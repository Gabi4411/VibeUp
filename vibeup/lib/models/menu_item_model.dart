import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String eventId;
  final String name;
  final String category; // 'Champagne', 'Vodka', 'Whiskey', 'Mixers', 'Food'
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final int stockQuantity;

  MenuItem({
    required this.id,
    required this.eventId,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.stockQuantity = 999,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
    };
  }

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      stockQuantity: data['stockQuantity'] ?? 999,
    );
  }

  MenuItem copyWith({
    String? id,
    String? eventId,
    String? name,
    String? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    int? stockQuantity,
  }) {
    return MenuItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}