import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/scheduled_route_model.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRide(RideModel ride) async {
    await _firestore.collection('rides').add(ride.toMap());
  }

  Future<void> updateRide(RideModel ride) async {
    await _firestore.collection('rides').doc(ride.id).update(ride.toMap());
  }

  Stream<List<RideModel>> getPendingRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          var rides = snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
          rides.sort((a, b) {
            final timeA = a.createdAt ?? a.dateTime;
            final timeB = b.createdAt ?? b.dateTime;
            return timeB.compareTo(timeA);
          });
          return rides;
        });
  }

  Stream<RideModel?> getRideStream(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RideModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Stream<List<RideModel>> getActiveRidesForUser(String userId) {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RideModel.fromFirestore(doc))
              .where((ride) => ride.driverId == userId || ride.creatorId == userId)
              .toList();
        });
  }

  // Lấy TẤT CẢ các chuyến xe liên quan đến User này để làm Filter trong "Quản lý ghi chú"
  Stream<List<RideModel>> getAllRidesForUser(String userId) {
    return _firestore
        .collection('rides')
        .snapshots()
        .map((snapshot) {
          var rides = snapshot.docs
              .map((doc) => RideModel.fromFirestore(doc))
              .where((ride) => ride.driverId == userId || ride.creatorId == userId)
              .toList();
          
          // Sắp xếp mới nhất lên đầu
          rides.sort((a, b) {
            final timeA = a.createdAt ?? a.dateTime;
            final timeB = b.createdAt ?? b.dateTime;
            return timeB.compareTo(timeA);
          });
          
          return rides;
        });
  }

  Stream<List<RideModel>> getOngoingRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList());
  }

  Stream<List<RideModel>> getHistoryRides(String userId) {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RideModel.fromFirestore(doc))
              .where((ride) => ride.driverId == userId || ride.creatorId == userId)
              .toList();
        });
  }

  Future<void> acceptRide(String rideId, String driverId, String driverName, String driverPhone) async {
    await _firestore.collection('rides').doc(rideId).update({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'acceptedAt': FieldValue.serverTimestamp(),
      'status': 'ongoing',
    });
  }

  Future<Map<String, dynamic>> cancelRide(String rideId, String driverId, {String? reason}) async {
    final rideDoc = await _firestore.collection('rides').doc(rideId).get();
    if (!rideDoc.exists) {
      return {'success': false, 'message': 'Không tìm thấy chuyến xe'};
    }
    
    final rideData = rideDoc.data()!;
    
    // Log lần hủy
    await _firestore.collection('ride_cancellations').add({
      'rideId': rideId,
      'driverId': driverId,
      'driverName': rideData['driverName'],
      'customerPhone': rideData['customerPhone'],
      'pickupPoint': rideData['pickupPoint'],
      'destinationPoint': rideData['destinationPoint'],
      'reason': reason ?? 'Không có lý do',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    
    // Cập nhật số lần hủy trong profile user
    await _firestore.collection('users').doc(driverId).set({
      'totalCancellations': FieldValue.increment(1),
      'lastCancellationAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Reset trạng thái chuyến
    await _firestore.collection('rides').doc(rideId).update({
      'driverId': null,
      'driverName': null,
      'driverPhone': null,
      'acceptedAt': null,
      'status': 'pending',
    });
    
    return {'success': true, 'message': 'Đã hủy chuyến thành công'};
  }

  Future<void> completeRide(String rideId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'completed',
    });
  }

  Future<void> deleteRide(String rideId) async {
    await _firestore.collection('rides').doc(rideId).delete();
  }

  Future<RideModel?> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        return RideModel.fromFirestore(doc);
      }
    } catch (e) {}
    return null;
  }

  // Scheduled Routes Methods
  Future<void> createScheduledRoute(ScheduledRouteModel route) async {
    await _firestore.collection('scheduled_routes').add(route.toMap());
  }

  Stream<List<ScheduledRouteModel>> getActiveScheduledRoutes() {
    final now = DateTime.now();
    return _firestore
        .collection('scheduled_routes')
        .where('departureTime', isGreaterThan: Timestamp.fromDate(now))
        .where('status', isEqualTo: 'active')
        .orderBy('departureTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ScheduledRouteModel.fromFirestore(doc)).toList());
  }

  Stream<List<ScheduledRouteModel>> getMyScheduledRoutes(String creatorId) {
    return _firestore
        .collection('scheduled_routes')
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'active')
        .orderBy('departureTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ScheduledRouteModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteScheduledRoute(String routeId) async {
    await _firestore.collection('scheduled_routes').doc(routeId).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<ScheduledRouteModel?> getScheduledRouteById(String routeId) async {
    try {
      final doc = await _firestore.collection('scheduled_routes').doc(routeId).get();
      if (doc.exists) {
        return ScheduledRouteModel.fromFirestore(doc);
      }
    } catch (e) {}
    return null;
  }
}
