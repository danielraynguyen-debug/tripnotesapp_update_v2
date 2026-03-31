import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String customerPhone;
  final String pickupPoint;
  final String destinationPoint;
  final DateTime dateTime;
  final double price;
  final String distance;
  final String status; // pending, ongoing, completed, cancelled
  final String type; // one_way, round_trip
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  
  final String? creatorId;
  final String? creatorName;
  final String? creatorPhone;
  final DateTime? createdAt;
  final DateTime? acceptedAt;

  RideModel({
    required this.id,
    required this.customerPhone,
    required this.pickupPoint,
    required this.destinationPoint,
    required this.dateTime,
    required this.price,
    required this.distance,
    required this.status,
    required this.type,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    this.creatorId,
    this.creatorName,
    this.creatorPhone,
    this.createdAt,
    this.acceptedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerPhone': customerPhone,
      'pickupPoint': pickupPoint,
      'destinationPoint': destinationPoint,
      'dateTime': Timestamp.fromDate(dateTime),
      'price': price,
      'distance': distance,
      'status': status,
      'type': type,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destLat': destLat,
      'destLng': destLng,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhone': creatorPhone,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      customerPhone: data['customerPhone'] ?? '',
      pickupPoint: data['pickupPoint'] ?? '',
      destinationPoint: data['destinationPoint'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      price: (data['price'] as num).toDouble(),
      distance: data['distance'] ?? '',
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'one_way',
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      pickupLat: (data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLng'] as num?)?.toDouble(),
      destLat: (data['destLat'] as num?)?.toDouble(),
      destLng: (data['destLng'] as num?)?.toDouble(),
      creatorId: data['creatorId'],
      creatorName: data['creatorName'],
      creatorPhone: data['creatorPhone'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
    );
  }
}
