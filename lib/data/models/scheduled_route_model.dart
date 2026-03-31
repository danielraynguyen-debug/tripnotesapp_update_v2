import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class ScheduledRouteModel {
  final String id;
  final String pickupPoint;
  final String destinationPoint;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  final DateTime departureTime;
  final String vehicleType;
  final int availableSeats;
  final double price;
  final String notes;
  final bool isPremiumFeature;
  final String creatorId;
  final String? creatorName;
  final String? creatorPhone;
  final DateTime? createdAt;
  final String status;

  ScheduledRouteModel({
    required this.id,
    required this.pickupPoint,
    required this.destinationPoint,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    required this.departureTime,
    required this.vehicleType,
    required this.availableSeats,
    required this.price,
    this.notes = '',
    this.isPremiumFeature = false,
    required this.creatorId,
    this.creatorName,
    this.creatorPhone,
    this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'pickupPoint': pickupPoint,
      'destinationPoint': destinationPoint,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destLat': destLat,
      'destLng': destLng,
      'departureTime': Timestamp.fromDate(departureTime),
      'vehicleType': vehicleType,
      'availableSeats': availableSeats,
      'price': price,
      'notes': notes,
      'isPremiumFeature': isPremiumFeature,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhone': creatorPhone,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  factory ScheduledRouteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScheduledRouteModel(
      id: doc.id,
      pickupPoint: data['pickupPoint'] ?? '',
      destinationPoint: data['destinationPoint'] ?? '',
      pickupLat: (data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLng'] as num?)?.toDouble(),
      destLat: (data['destLat'] as num?)?.toDouble(),
      destLng: (data['destLng'] as num?)?.toDouble(),
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      vehicleType: data['vehicleType'] ?? '4 chỗ',
      availableSeats: data['availableSeats'] ?? 4,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] ?? '',
      isPremiumFeature: data['isPremiumFeature'] ?? false,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'],
      creatorPhone: data['creatorPhone'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'active',
    );
  }

  String get formattedPrice {
    if (price <= 0) return 'Thỏa thuận';
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final priceStr = price.toStringAsFixed(0);
    return priceStr.replaceAllMapped(formatter, (m) => '${m[1]}.') + ' đ';
  }

  // Calculate distance between pickup and destination in km
  String get distance {
    if (pickupLat == null || pickupLng == null || destLat == null || destLng == null) {
      return '0 km';
    }
    
    // Haversine formula
    const R = 6371; // Earth's radius in km
    final lat1Rad = pickupLat! * (math.pi / 180);
    final lat2Rad = destLat! * (math.pi / 180);
    final deltaLat = (destLat! - pickupLat!) * (math.pi / 180);
    final deltaLng = (destLng! - pickupLng!) * (math.pi / 180);
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) * 
              math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distanceKm = R * c;
    
    return '${distanceKm.toStringAsFixed(2)} km';
  }
}
