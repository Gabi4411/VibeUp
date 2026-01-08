import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../models/table_order_model.dart';
import '../services/menu_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'order_cart_screen.dart';

class TableMenuScreen extends StatefulWidget {
  final Event event;
  final VIPTable table;
  final String userId;
  final String userName;
  final AuthService authService;

  const TableMenuScreen({
    super.key,
    required this.event,
    required this.table,
    required this.userId,
    required this.userName,
    required this.authService,
  });

  @override
  State<TableMenuScreen> createState() => _TableMenuScreenState();
}

class _TableMenuScreenState extends State<TableMenuScreen> {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();
  String _selectedCategory = 'All';
  final Map<String, int> _cart = {}; // menuItemId -> quantity

  int get _cartItemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Table ${widget.table.tableNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1F2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // View orders button
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              // Navigate to active orders screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveOrdersScreen(
                    tableId: widget.table.id,
                    eventId: widget.event.id,
                    authService: widget.authService,
                  ),
                ),
              );
            },
          ),
          // Cart button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: _cartItemCount > 0 ? _viewCart : null,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF88),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),

          // Menu items
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: _menuService.getEventMenu(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF88)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading menu',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }

                var items = snapshot.data ?? [];

                // Filter by category
                if (_selectedCategory != 'All') {
                  items = items
                      .where((item) => item.category == _selectedCategory)
                      .toList();
                }

                // Filter only available items
                items = items.where((item) => item.isAvailable).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items available',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildMenuItem(items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartButton() : null,
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Champagne',
      'Vodka',
      'Whiskey',
      'Mixers',
      'Food'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFF1A1F2E),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: const Color(0xFF131722),
                selectedColor: const Color(0xFF00FF88),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF00FF88)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final quantityInCart = _cart[item.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantityInCart > 0
              ? const Color(0xFF00FF88)
              : Colors.white.withValues(alpha: 0.1),
          width: quantityInCart > 0 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item icon/image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: const Color(0xFF00FF88),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Add/Remove buttons
            if (quantityInCart == 0)
              IconButton(
                onPressed: () {
                  setState(() {
                    _cart[item.id] = 1;
                  });
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFF00FF88)),
                iconSize: 32,
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_cart[item.id]! > 1) {
                            _cart[item.id] = _cart[item.id]! - 1;
                          } else {
                            _cart.remove(item.id);
                          }
                        });
                      },
                      icon: const Icon(Icons.remove, color: Color(0xFF00FF88)),
                      iconSize: 20,
                    ),
                    Text(
                      '$quantityInCart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _cart[item.id] = _cart[item.id]! + 1;
                        });
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF00FF88)),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _viewCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 24),
              const SizedBox(width: 12),
              Text(
                'View Cart ($_cartItemCount items)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewCart() async {
    // Convert cart from Map<String, int> to Map<MenuItem, int>
    final menuItemsSnapshot = await _menuService
        .getEventMenu(widget.event.id)
        .first;
    
    final Map<MenuItem, int> cartItems = {};
    for (var entry in _cart.entries) {
      final menuItem = menuItemsSnapshot.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => MenuItem(
          id: entry.key,
          eventId: widget.event.id,
          name: 'Unknown Item',
          category: 'Other',
          price: 0,
        ),
      );
      cartItems[menuItem] = entry.value;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderCartScreen(
          cartItems: cartItems,
          event: widget.event,
          table: widget.table,
          userId: widget.userId,
          userName: widget.userName,
          authService: widget.authService,
        ),
      ),
    );

    if (result == true && mounted) {
      // Order was placed, clear cart
      setState(() {
        _cart.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Color(0xFF00FF88),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'champagne':
        return Icons.celebration;
      case 'vodka':
      case 'whiskey':
        return Icons.local_bar;
      case 'mixers':
        return Icons.local_drink;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.liquor;
    }
  }
}

// Active Orders Screen
class ActiveOrdersScreen extends StatelessWidget {
  final String tableId;
  final String eventId;
  final AuthService authService;

  const ActiveOrdersScreen({
    super.key,
    required this.tableId,
    required this.eventId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Orders',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<TableOrder>>(
        stream: orderService.getTableOrders(tableId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading orders',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index], authService);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    TableOrder order,
    AuthService authService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(order.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatOrderTime(order.orderedAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),

          // Order items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!order.isPaid && order.status == 'delivered')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _payForOrder(context, order, authService);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'paid':
        return const Color(0xFF00FF88);
      default:
        return Colors.grey;
    }
  }

  String _formatOrderTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _payForOrder(
    BuildContext context,
    TableOrder order,
    AuthService authService,
  ) async {
    // Check balance
    if (authService.balance < order.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final orderService = OrderService();
      
      // Deduct money
      await authService.deductMoney(order.totalAmount);
      
      // Mark as paid
      await orderService.markOrderPaid(order.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}