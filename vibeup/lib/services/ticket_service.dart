import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import '../models/event_model.dart';

class TicketService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  TicketService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Purchase a ticket
  Future<String> purchaseTicket({
    required Event event,
    required String userId,
    required String ticketType,
    required double price,
  }) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    // Check if user already has a ticket for this event
    final alreadyHasTicket = await hasTicketForEvent(userId, event.id);
    if (alreadyHasTicket) {
      throw Exception('You already have a ticket for this event');
    }

    try {
      final ticket = Ticket(
        id: '',
        eventId: event.id,
        eventName: event.name,
        eventLocation: event.location,
        eventDateTime: event.dateTime,
        eventTime: event.time,
        userId: userId,
        ticketType: ticketType,
        price: price,
        purchasedAt: DateTime.now(),
      );

      final docRef = await _firestore!
          .collection('tickets')
          .add(ticket.toMap());

      // Increment attendance count for the event
      await _firestore!.collection('events').doc(event.id).update({
        'attendanceCount': FieldValue.increment(1),
      });

      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error purchasing ticket: $e');
      throw Exception('Failed to purchase ticket: $e');
    }
  }

  // Get user's tickets
  Stream<List<Ticket>> getUserTickets(String userId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs
              .map((doc) => Ticket.fromFirestore(doc))
              .toList();
          // Sort by event date (upcoming events first)
          tickets.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
          return tickets;
        });
  }

  // Delete a ticket (cancel attendance)
  Future<void> deleteTicket(String ticketId, String eventId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      // Delete the ticket
      await _firestore!.collection('tickets').doc(ticketId).delete();

      // Decrement attendance count for the event
      await _firestore!.collection('events').doc(eventId).update({
        'attendanceCount': FieldValue.increment(-1),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      throw Exception('Failed to delete ticket: $e');
    }
  }

  // Check if user has a ticket for an event
  Future<bool> hasTicketForEvent(String userId, String eventId) async {
    if (_firestore == null) {
      return false;
    }

    try {
      final snapshot = await _firestore!
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking ticket: $e');
      return false;
    }
  }

  // Get ticket for specific event (if exists)
  Future<Ticket?> getTicketForEvent(String userId, String eventId) async {
    if (_firestore == null) {
      return null;
    }

    try {
      final snapshot = await _firestore!
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Ticket.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting ticket: $e');
      return null;
    }
  }

  // Get all tickets for a specific event (for analytics)
  Stream<List<Ticket>> getEventTickets(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('tickets')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs
              .map((doc) => Ticket.fromFirestore(doc))
              .toList();
          // Sort by purchase date (newest first)
          tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
          return tickets;
        });
  }
}
