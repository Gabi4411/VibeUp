import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/table_order_model.dart';
import '../services/order_service.dart';

class OrderDashboardScreen extends StatefulWidget {
  final Event event;

  const OrderDashboardScreen({
    super.key,
    required this.event,
  });

  @override
  State<OrderDashboardScreen> createState() => _OrderDashboardScreenState();
}

class _OrderDashboardScreenState extends State<OrderDashboardScreen> {
  final OrderService _orderService = OrderService();
  String _filterStatus = 'All';
  String _filterTable = 'All';

  final List<String> _statusFilters = [
    'All',
    'pending',
    'confirmed',
    'preparing',
    'delivered',
    'paid',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Event Info & Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1F2E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<TableOrder>>(
                    stream: _orderService.getEventOrders(widget.event.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final orders = snapshot.data!;
                      final totalRevenue = orders.fold<double>(
                        0.0,
                        (sum, order) => sum + order.totalAmount,
                      );
                      final unpaidAmount = orders
                          .where((o) => !o.isPaid)
                          .fold<double>(
                            0.0,
                            (sum, order) => sum + order.totalAmount,
                          );

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Orders',
                              orders.length.toString(),
                              Icons.receipt_long,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Revenue',
                              '\$${totalRevenue.toStringAsFixed(0)}',
                              Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Unpaid',
                              '\$${unpaidAmount.toStringAsFixed(0)}',
                              Icons.warning,
                              color: unpaidAmount > 0 ? Colors.orange : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Status',
                      _filterStatus,
                      _statusFilters,
                      (value) {
                        setState(() {
                          _filterStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<List<TableOrder>>(
                      stream: _orderService.getEventOrders(widget.event.id),
                      builder: (context, snapshot) {
                        final tables = <String>['All'];
                        if (snapshot.hasData) {
                          final uniqueTables = snapshot.data!
                              .map((o) => o.tableNumber)
                              .toSet()
                              .toList()
                            ..sort();
                          tables.addAll(uniqueTables);
                        }

                        return _buildFilterDropdown(
                          'Table',
                          _filterTable,
                          tables,
                          (value) {
                            setState(() {
                              _filterTable = value!;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: StreamBuilder<List<TableOrder>>(
                stream: _orderService.getEventOrders(widget.event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FF88),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  var orders = snapshot.data ?? [];

                  // Apply filters
                  if (_filterStatus != 'All') {
                    orders = orders
                        .where((o) => o.status == _filterStatus)
                        .toList();
                  }
                  if (_filterTable != 'All') {
                    orders = orders
                        .where((o) => o.tableNumber == _filterTable)
                        .toList();
                  }

                  // Sort by most recent first
                  orders.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
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
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final displayColor = color ?? const Color(0xFF00FF88);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: displayColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: displayColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1F2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dropdownColor: const Color(0xFF1A1F2E),
      style: const TextStyle(color: Colors.white),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item == 'All' ? item : item.toUpperCase(),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOrderCard(TableOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(order.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.table_bar,
                            color: _getStatusColor(order.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Table ${order.tableNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.userName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy h:mm a').format(order.orderedAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!order.isPaid)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          'UNPAID',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  color: Color(0xFF00FF88),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          // Action Buttons
          if (order.status != 'delivered' && order.status != 'paid')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (order.status == 'pending')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order, 'confirmed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  if (order.status == 'confirmed') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order, 'preparing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Start Preparing'),
                      ),
                    ),
                  ],
                  if (order.status == 'preparing') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order, 'delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Mark Delivered'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'delivered':
        return const Color(0xFF00FF88);
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(TableOrder order, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
