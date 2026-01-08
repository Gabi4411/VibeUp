import 'package:cloud_firestore/cloud_firestore.dart';

class TableOrder {
  final String id;
  final String eventId;
  final String tableId;
  final String tableNumber;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'preparing', 'delivered', 'paid'
  final bool isPaid;
  final DateTime orderedAt;
  final DateTime? deliveredAt;
  final DateTime? paidAt;

  TableOrder({
    required this.id,
    required this.eventId,
    required this.tableId,
    required this.tableNumber,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    this.isPaid = false,
    required this.orderedAt,
    this.deliveredAt,
    this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'isPaid': isPaid,
      'orderedAt': Timestamp.fromDate(orderedAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  factory TableOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableOrder(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      tableId: data['tableId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      isPaid: data['isPaid'] ?? false,
      orderedAt: (data['orderedAt'] as Timestamp).toDate(),
      deliveredAt: data['deliveredAt'] != null 
          ? (data['deliveredAt'] as Timestamp).toDate() 
          : null,
      paidAt: data['paidAt'] != null 
          ? (data['paidAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      specialInstructions: map['specialInstructions'],
    );
  }

  double get subtotal => price * quantity;
}