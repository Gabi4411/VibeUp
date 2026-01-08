import 'package:cloud_firestore/cloud_firestore.dart';

class VIPTable {
  final String id;
  final String eventId;
  final String tableNumber;
  final int capacity;
  final double bookingPrice;
  final String location; // 'VIP Section', 'Main Floor', etc.
  final bool isBooked;
  final String? bookedByUserId;
  final String? bookedByUserName;
  final DateTime? bookedAt;
  final double totalSpent; // Total amount spent on orders
  final double totalDue; // Amount still unpaid

  VIPTable({
    required this.id,
    required this.eventId,
    required this.tableNumber,
    required this.capacity,
    required this.bookingPrice,
    required this.location,
    this.isBooked = false,
    this.bookedByUserId,
    this.bookedByUserName,
    this.bookedAt,
    this.totalSpent = 0.0,
    this.totalDue = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'bookingPrice': bookingPrice,
      'location': location,
      'isBooked': isBooked,
      'bookedByUserId': bookedByUserId,
      'bookedByUserName': bookedByUserName,
      'bookedAt': bookedAt != null ? Timestamp.fromDate(bookedAt!) : null,
      'totalSpent': totalSpent,
      'totalDue': totalDue,
    };
  }

  factory VIPTable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VIPTable(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      capacity: data['capacity'] ?? 4,
      bookingPrice: (data['bookingPrice'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      isBooked: data['isBooked'] ?? false,
      bookedByUserId: data['bookedByUserId'],
      bookedByUserName: data['bookedByUserName'],
      bookedAt: data['bookedAt'] != null 
          ? (data['bookedAt'] as Timestamp).toDate() 
          : null,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      totalDue: (data['totalDue'] ?? 0).toDouble(),
    );
  }

  VIPTable copyWith({
    String? id,
    String? eventId,
    String? tableNumber,
    int? capacity,
    double? bookingPrice,
    String? location,
    bool? isBooked,
    String? bookedByUserId,
    String? bookedByUserName,
    DateTime? bookedAt,
    double? totalSpent,
    double? totalDue,
  }) {
    return VIPTable(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      bookingPrice: bookingPrice ?? this.bookingPrice,
      location: location ?? this.location,
      isBooked: isBooked ?? this.isBooked,
      bookedByUserId: bookedByUserId ?? this.bookedByUserId,
      bookedByUserName: bookedByUserName ?? this.bookedByUserName,
      bookedAt: bookedAt ?? this.bookedAt,
      totalSpent: totalSpent ?? this.totalSpent,
      totalDue: totalDue ?? this.totalDue,
    );
  }
}