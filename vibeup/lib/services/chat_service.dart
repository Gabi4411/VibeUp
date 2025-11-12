import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  ChatService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Send a message to an event chat
  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    if (text.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final message = Message(
        id: '',
        eventId: eventId,
        userId: userId,
        userName: userName,
        text: text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestore!.collection('messages').add(message.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a specific event
  Stream<List<Message>> getEventMessages(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('messages')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
          // Sort by timestamp in memory (ascending - oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Delete a message (only by the sender)
  Future<void> deleteMessage(String messageId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('messages').doc(messageId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get message count for an event
  Future<int> getMessageCount(String eventId) async {
    if (_firestore == null) {
      return 0;
    }

    try {
      final snapshot = await _firestore!
          .collection('messages')
          .where('eventId', isEqualTo: eventId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting message count: $e');
      return 0;
    }
  }
}
