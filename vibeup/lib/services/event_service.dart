import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

class EventService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  EventService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Create a new event
  Future<String> createEvent(Event event) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final docRef = await _firestore!.collection('events').add(event.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  // Update an existing event
  Future<void> updateEvent(String eventId, Event event) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('events').doc(eventId).update(event.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('events').doc(eventId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get all public events
  Stream<List<Event>> getPublicEvents() {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();
          // Sort by date in memory
          events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return events;
        });
  }

  // Get events created by a specific user (developer)
  Stream<List<Event>> getDeveloperEvents(String userId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('events')
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();
          // Sort by created date in memory (newest first)
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  } // Get a single event by ID

  Future<Event?> getEventById(String eventId) async {
    if (_firestore == null) {
      return null;
    }

    try {
      final doc = await _firestore!.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  // Increment attendance count
  Future<void> incrementAttendance(String eventId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('events').doc(eventId).update({
        'attendanceCount': FieldValue.increment(1),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error incrementing attendance: $e');
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Decrement attendance count
  Future<void> decrementAttendance(String eventId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('events').doc(eventId).update({
        'attendanceCount': FieldValue.increment(-1),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error decrementing attendance: $e');
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Search events by name or location
  Stream<List<Event>> searchEvents(String query) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    // Note: This is a simple search. For production, consider using Algolia or similar
    return _firestore!
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .where(
                (event) =>
                    event.name.toLowerCase().contains(query.toLowerCase()) ||
                    event.location.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        });
  }

  // Get events by category
  Stream<List<Event>> getEventsByCategory(String category) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();
          // Sort by date in memory
          events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return events;
        });
  }
}
