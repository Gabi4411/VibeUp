import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String eventId;
  final String eventName;
  final String eventLocation;
  final DateTime eventDateTime;
  final String eventTime;
  final String userId;
  final String ticketType; // 'GA' or 'VIP'
  final double price;
  final DateTime purchasedAt;

  Ticket({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventLocation,
    required this.eventDateTime,
    required this.eventTime,
    required this.userId,
    required this.ticketType,
    required this.price,
    required this.purchasedAt,
  });

  // Convert Ticket to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'eventLocation': eventLocation,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'eventTime': eventTime,
      'userId': userId,
      'ticketType': ticketType,
      'price': price,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
    };
  }

  // Create Ticket from Firestore document
  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ticket(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventLocation: data['eventLocation'] ?? '',
      eventDateTime: (data['eventDateTime'] as Timestamp).toDate(),
      eventTime: data['eventTime'] ?? '',
      userId: data['userId'] ?? '',
      ticketType: data['ticketType'] ?? 'GA',
      price: (data['price'] ?? 0).toDouble(),
      purchasedAt: (data['purchasedAt'] as Timestamp).toDate(),
    );
  }

  // Helper method to format date for display
  String get formattedDate {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[eventDateTime.month - 1];
  }

  String get formattedDay {
    return eventDateTime.day.toString();
  }
}
