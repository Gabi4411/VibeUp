import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';

class MenuService extends ChangeNotifier {
  FirebaseFirestore? _firestore;

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  MenuService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Create menu item
  Future<String> createMenuItem(MenuItem item) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final docRef = await _firestore!.collection('menu_items').add(item.toMap());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating menu item: $e');
      throw Exception('Failed to create menu item: $e');
    }
  }

  // Get menu items for event
  Stream<List<MenuItem>> getEventMenu(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    return _firestore!
        .collection('menu_items')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MenuItem.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.category.compareTo(b.category));
        });
  }

  // Update menu item
  Future<void> updateMenuItem(String itemId, Map<String, dynamic> updates) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('menu_items').doc(itemId).update(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      throw Exception('Failed to update menu item: $e');
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String itemId) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('menu_items').doc(itemId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      throw Exception('Failed to delete menu item: $e');
    }
  }

  // Alias for getEventMenu (for compatibility)
  Stream<List<MenuItem>> getEventMenuItems(String eventId) {
    return getEventMenu(eventId);
  }

  // Toggle item availability
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    if (_firestore == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      await _firestore!.collection('menu_items').doc(itemId).update({
        'isAvailable': isAvailable,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling item availability: $e');
      throw Exception('Failed to toggle item availability: $e');
    }
  }
}