import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/table_order_model.dart';

class OrderService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  OrderService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Create order
  Future<String> createOrder(TableOrder order) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final docRef = await _firestore!.collection('table_orders').add(order.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  // Get orders for table
  Stream<List<TableOrder>> getTableOrders(String tableId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('table_orders')
        .where('tableId', isEqualTo: tableId)
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TableOrder.fromFirestore(doc))
              .toList();
        });
  }

  // Get all orders for event
  Stream<List<TableOrder>> getEventOrders(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('table_orders')
        .where('eventId', isEqualTo: eventId)
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TableOrder.fromFirestore(doc))
              .toList();
        });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final updates = <String, dynamic>{'status': status};
      
      if (status == 'delivered') {
        updates['deliveredAt'] = Timestamp.now();
      }

      await _firestore!.collection('table_orders').doc(orderId).update(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Mark order as paid
  Future<void> markOrderPaid(String orderId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('table_orders').doc(orderId).update({
        'isPaid': true,
        'paidAt': Timestamp.now(),
        'status': 'paid',
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking order paid: $e');
      throw Exception('Failed to mark order paid: $e');
    }
  }
}