import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../models/table_booking_model.dart';

class TableService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  TableService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Create table
  Future<String> createTable(VIPTable table) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final docRef = await _firestore!.collection('tables').add(table.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating table: $e');
      throw Exception('Failed to create table: $e');
    }
  }

  // Get tables for event
  Stream<List<VIPTable>> getEventTables(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('tables')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VIPTable.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
        });
  }

  // Book table
  Future<void> bookTable({
    required String tableId,
    required String userId,
    required String userName,
    required double bookingPrice,
    required String eventId,
    required String tableNumber,
  }) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final batch = _firestore!.batch();

      // Update table status
      batch.update(_firestore!.collection('tables').doc(tableId), {
        'isBooked': true,
        'bookedByUserId': userId,
        'bookedByUserName': userName,
        'bookedAt': Timestamp.now(),
        'totalSpent': FieldValue.increment(bookingPrice), // Mark booking fee as paid
      });

      // Create booking record
      final booking = TableBooking(
        id: '',
        eventId: eventId,
        tableId: tableId,
        userId: userId,
        userName: userName,
        tableNumber: tableNumber,
        bookingPrice: bookingPrice,
        bookedAt: DateTime.now(),
      );

      batch.set(
        _firestore!.collection('table_bookings').doc(),
        booking.toMap(),
      );

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error booking table: $e');
      throw Exception('Failed to book table: $e');
    }
  }

  // Get user's table booking for event
  Future<TableBooking?> getUserTableBooking(String userId, String eventId) async {
    if (_firestore == null) {
      return null;
    }

    try {
      final snapshot = await _firestore!
          .collection('table_bookings')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return TableBooking.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting table booking: $e');
      return null;
    }
  }

  // Update table totals
  Future<void> updateTableTotals(String tableId, double spent, double due) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('tables').doc(tableId).update({
        'totalSpent': FieldValue.increment(spent),
        'totalDue': FieldValue.increment(due),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating table totals: $e');
      throw Exception('Failed to update table totals: $e');
    }
  }

  // Delete table
  Future<void> deleteTable(String tableId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('tables').doc(tableId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting table: $e');
      throw Exception('Failed to delete table: $e');
    }
  }

  // Update table
  Future<void> updateTable(String tableId, Map<String, dynamic> updates) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('tables').doc(tableId).update(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating table: $e');
      throw Exception('Failed to update table: $e');
    }
  }
}