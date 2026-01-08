import 'package:cloud_firestore/cloud_firestore.dart';

class TableBooking {
  final String id;
  final String eventId;
  final String tableId;
  final String userId;
  final String userName;
  final String tableNumber;
  final double bookingPrice;
  final DateTime bookedAt;
  final bool isActive;

  TableBooking({
    required this.id,
    required this.eventId,
    required this.tableId,
    required this.userId,
    required this.userName,
    required this.tableNumber,
    required this.bookingPrice,
    required this.bookedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'tableId': tableId,
      'userId': userId,
      'userName': userName,
      'tableNumber': tableNumber,
      'bookingPrice': bookingPrice,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'isActive': isActive,
    };
  }

  factory TableBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableBooking(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      tableId: data['tableId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      bookingPrice: (data['bookingPrice'] ?? 0).toDouble(),
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}