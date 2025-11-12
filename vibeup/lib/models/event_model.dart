import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String location;
  final String description;
  final DateTime dateTime;
  final String time;
  final String category;
  final List<String> tags;
  final bool isPublic;
  final double? ticketPrice;
  final String? ticketPriceVIP;
  final String creatorId;
  final String creatorName;
  final int attendanceCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.dateTime,
    required this.time,
    required this.category,
    required this.tags,
    required this.isPublic,
    this.ticketPrice,
    this.ticketPriceVIP,
    required this.creatorId,
    required this.creatorName,
    this.attendanceCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Event to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'time': time,
      'category': category,
      'tags': tags,
      'isPublic': isPublic,
      'ticketPrice': ticketPrice,
      'ticketPriceVIP': ticketPriceVIP,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'attendanceCount': attendanceCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isPublic: data['isPublic'] ?? true,
      ticketPrice: data['ticketPrice']?.toDouble(),
      ticketPriceVIP: data['ticketPriceVIP'],
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      attendanceCount: data['attendanceCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create a copy of Event with updated fields
  Event copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    DateTime? dateTime,
    String? time,
    String? category,
    List<String>? tags,
    bool? isPublic,
    double? ticketPrice,
    String? ticketPriceVIP,
    String? creatorId,
    String? creatorName,
    int? attendanceCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      time: time ?? this.time,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ticketPriceVIP: ticketPriceVIP ?? this.ticketPriceVIP,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return months[dateTime.month - 1];
  }

  String get formattedDay {
    return dateTime.day.toString();
  }
}
