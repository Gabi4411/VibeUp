import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/table_model.dart';
import '../models/table_booking_model.dart';
import '../services/table_service.dart';
import '../services/auth_service.dart';
import 'table_menu_screen.dart';

class TableBookingScreen extends StatefulWidget {
  final Event event;
  final String userId;
  final String userName;
  final AuthService authService;

  const TableBookingScreen({
    super.key,
    required this.event,
    required this.userId,
    required this.userName,
    required this.authService,
  });

  @override
  State<TableBookingScreen> createState() => _TableBookingScreenState();
}

class _TableBookingScreenState extends State<TableBookingScreen> {
  final TableService _tableService = TableService();
  String _selectedLocation = 'All';
  TableBooking? _existingBooking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingBooking();
  }

  Future<void> _checkExistingBooking() async {
    final booking = await _tableService.getUserTableBooking(
      widget.userId,
      widget.event.id,
    );
    
    if (mounted) {
      setState(() {
        _existingBooking = booking;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book a Table',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            )
          : _existingBooking != null
              ? _buildExistingBookingView()
              : _buildTableSelectionView(),
    );
  }

  Widget _buildExistingBookingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Table Reserved!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Table ${_existingBooking!.tableNumber}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Table info card
          _buildInfoCard(
            icon: Icons.event,
            title: 'Event',
            value: widget.event.name,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.table_bar,
            title: 'Table Number',
            value: _existingBooking!.tableNumber,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.attach_money,
            title: 'Booking Price',
            value: '\$${_existingBooking!.bookingPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 24),

          // Order from menu button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Get the table details first
                final tables = await _tableService
                    .getEventTables(widget.event.id)
                    .first;
                final table = tables.firstWhere(
                  (t) => t.id == _existingBooking!.tableId,
                );

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TableMenuScreen(
                        event: widget.event,
                        table: table,
                        userId: widget.userId,
                        userName: widget.userName,
                        authService: widget.authService,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.restaurant_menu, size: 24),
              label: const Text(
                'Order from Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelectionView() {
    return Column(
      children: [
        // Location filter
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1F2E),
          child: Row(
            children: [
              const Text(
                'Location:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLocationChip('All'),
                      const SizedBox(width: 8),
                      _buildLocationChip('VIP Section'),
                      const SizedBox(width: 8),
                      _buildLocationChip('Main Floor'),
                      const SizedBox(width: 8),
                      _buildLocationChip('Balcony'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Available tables
        Expanded(
          child: StreamBuilder<List<VIPTable>>(
            stream: _tableService.getEventTables(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FF88)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading tables',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }

              var tables = snapshot.data ?? [];
              
              // Filter by location
              if (_selectedLocation != 'All') {
                tables = tables
                    .where((t) => t.location == _selectedLocation)
                    .toList();
              }

              // Filter out booked tables
              final availableTables =
                  tables.where((t) => !t.isBooked).toList();

              if (availableTables.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tables available',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: availableTables.length,
                itemBuilder: (context, index) {
                  return _buildTableCard(availableTables[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChip(String location) {
    final isSelected = _selectedLocation == location;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocation = location;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          location,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(VIPTable table) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBookingConfirmation(table),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.table_bar,
                  color: Color(0xFF00FF88),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Table ${table.tableNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  table.location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${table.capacity} seats',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${table.bookingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingConfirmation(VIPTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${table.tableNumber}',
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Location', table.location),
            _buildDetailRow('Capacity', '${table.capacity} people'),
            _buildDetailRow(
              'Price',
              '\$${table.bookingPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF00FF88),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Balance: \$${widget.authService.balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Check balance
              if (widget.authService.balance < table.bookingPrice) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              try {
                // Deduct from balance
                await widget.authService.deductMoney(table.bookingPrice);

                // Book table
                await _tableService.bookTable(
                  tableId: table.id,
                  userId: widget.userId,
                  userName: widget.userName,
                  bookingPrice: table.bookingPrice,
                  eventId: widget.event.id,
                  tableNumber: table.tableNumber,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _checkExistingBooking(); // Refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Table booked successfully!'),
                      backgroundColor: Color(0xFF00FF88),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF88), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}