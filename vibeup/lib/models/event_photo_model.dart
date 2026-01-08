import 'package:cloud_firestore/cloud_firestore.dart';

class EventPhoto {
  final String id;
  final String eventId;
  final String uploaderId;
  final String uploaderName;
  final String imageUrl;
  final DateTime uploadedAt;
  final bool isOrganizerPhoto;

  EventPhoto({
    required this.id,
    required this.eventId,
    required this.uploaderId,
    required this.uploaderName,
    required this.imageUrl,
    required this.uploadedAt,
    required this.isOrganizerPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isOrganizerPhoto': isOrganizerPhoto,
    };
  }

  factory EventPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventPhoto(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      uploaderName: data['uploaderName'] ?? 'Unknown',
      imageUrl: data['imageUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOrganizerPhoto: data['isOrganizerPhoto'] ?? false,
    );
  }
}