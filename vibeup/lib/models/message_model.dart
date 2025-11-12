import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  // Convert Message to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create Message from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Helper to check if message is from current user
  bool isFromUser(String currentUserId) {
    return userId == currentUserId;
  }
}
