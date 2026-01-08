import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/event_photo_model.dart';

class PhotoService extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  PhotoService() {
    if (_isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
        _storage = FirebaseStorage.instance;
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    }
  }

  // Upload photo (works for web and mobile)
  Future<String> uploadPhoto({
    required String eventId,
    required String userId,
    required String userName,
    required dynamic file, // XFile or File or Uint8List
    required bool isOrganizerPhoto,
  }) async {
    if (_firestore == null || _storage == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'event_photos/$eventId/$fileName';
      
      // Upload file
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web, file should be Uint8List
        if (file is! Uint8List) {
          throw Exception('Invalid file type for web upload');
        }
        uploadTask = _storage!.ref(path).putData(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile, file should be File
        if (file is! File) {
          throw Exception('Invalid file type for mobile upload');
        }
        uploadTask = _storage!.ref(path).putFile(file);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create photo document in Firestore
      final photoData = {
        'eventId': eventId,
        'uploaderId': userId,
        'uploaderName': userName,
        'imageUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'isOrganizerPhoto': isOrganizerPhoto,
      };

      final docRef = await _firestore!.collection('photos').add(photoData);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Get all photos for an event
  Stream<List<EventPhoto>> getEventPhotos(String eventId) {
    if (_firestore == null) {
      return Stream.value([]);
    }

    try {
      return _firestore!
          .collection('photos')
          .where('eventId', isEqualTo: eventId)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => EventPhoto.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('Error getting event photos: $e');
      // If the query fails due to index, return without ordering
      return _firestore!
          .collection('photos')
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map((snapshot) {
            final photos = snapshot.docs
                .map((doc) => EventPhoto.fromFirestore(doc))
                .toList();
            // Sort in memory instead
            photos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return photos;
          });
    }
  }

  // Get user's photos for a specific event
  Future<List<EventPhoto>> getUserPhotosForEvent(
    String eventId,
    String userId,
  ) async {
    if (_firestore == null) {
      return [];
    }

    try {
      final snapshot = await _firestore!
          .collection('photos')
          .where('eventId', isEqualTo: eventId)
          .where('uploaderId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EventPhoto.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user photos: $e');
      return [];
    }
  }

  // Delete photo
  Future<void> deletePhoto(String photoId, String imageUrl) async {
    if (_firestore == null || _storage == null) {
      throw Exception('Firebase is not initialized');
    }

    try {
      // Delete from Storage
      final ref = _storage!.refFromURL(imageUrl);
      await ref.delete();

      // Delete from Firestore
      await _firestore!.collection('photos').doc(photoId).delete();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      throw Exception('Failed to delete photo: $e');
    }
  }
}