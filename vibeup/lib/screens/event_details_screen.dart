import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/table_model.dart';
import '../widgets/purchase_ticket_dialog.dart';
import '../services/auth_service.dart';
import '../services/table_service.dart';
import 'table_booking_screen.dart';
import 'table_management_screen.dart';
import 'menu_management_screen.dart';
import 'table_menu_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  final String userId;
  final AuthService authService;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.userId,
    required this.authService,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final TableService _tableService = TableService();
  bool _hasTicket = false;
  VIPTable? _bookedTable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTicketAndTable();
  }

  Future<void> _checkTicketAndTable() async {
    try {
      // Check if user has a ticket
      final ticketSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: widget.userId)
          .where('eventId', isEqualTo: widget.event.id)
          .limit(1)
          .get();

      final hasTicket = ticketSnapshot.docs.isNotEmpty;

      // Check if user has booked a table
      VIPTable? bookedTable;
      if (hasTicket && widget.event.hasTableBooking) {
        final booking = await _tableService.getUserTableBooking(
          widget.userId,
          widget.event.id,
        );
        if (booking != null) {
          final tableSnapshot = await FirebaseFirestore.instance
              .collection('tables')
              .doc(booking.tableId)
              .get();
          if (tableSnapshot.exists) {
            bookedTable = VIPTable.fromFirestore(tableSnapshot);
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasTicket = hasTicket;
          _bookedTable = bookedTable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                  backgroundColor: Color(0xFF00FF88),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              // TODO: Implement save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event saved!'),
                  backgroundColor: Color(0xFF00FF88),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title
                    Text(
                      widget.event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Public/Private badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.event.isPublic
                            ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.event.isPublic
                              ? const Color(0xFF00FF88)
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.event.isPublic ? 'Public Event' : 'Private Event',
                        style: TextStyle(
                          color: widget.event.isPublic
                              ? const Color(0xFF00FF88)
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date & Time Card
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'Date & Time',
                      content: [
                        DateFormat(
                          'EEEE, MMMM dd, yyyy',
                        ).format(widget.event.dateTime),
                        widget.event.time,
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location Card
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: [widget.event.location],
                    ),
                    const SizedBox(height: 16),

                    // Category & Tags
                    _buildInfoCard(
                      icon: Icons.category,
                      title: 'Category',
                      content: [widget.event.category],
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (widget.event.tags.isNotEmpty) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.event.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00FF88),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description Card
                    _buildInfoCard(
                      icon: Icons.description,
                      title: 'About Event',
                      content: [widget.event.description],
                    ),
                    const SizedBox(height: 16),

                    // Organizer Info
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Organized by',
                      content: [widget.event.creatorName],
                    ),
                    const SizedBox(height: 16),

                    // Attendance
                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Attendance',
                      content: ['${widget.event.attendanceCount} people attending'],
                    ),
                    const SizedBox(height: 16),

                    // Ticket Pricing (if available)
                    if (widget.event.ticketPrice != null ||
                        widget.event.ticketPriceVIP != null) ...[
                      const Text(
                        'Ticket Prices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (widget.event.ticketPrice != null)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'General Admission',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '\$${widget.event.ticketPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.event.ticketPrice != null &&
                                widget.event.ticketPriceVIP != null)
                              const Divider(height: 24, color: Colors.white24),
                            if (widget.event.ticketPriceVIP != null)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'VIP Access',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${widget.event.ticketPriceVIP!}',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.celebration,
                              color: Color(0xFF00FF88),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Free Event',
                              style: TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Ticket Holder Features (only visible if user has ticket)
                    if (_hasTicket && !_isLoading) ...[
                      const Text(
                        'Your Ticket Benefits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // VIP Table Booking/Access
                      if (widget.event.hasTableBooking) ...[
                        if (_bookedTable == null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TableBookingScreen(
                                      event: widget.event,
                                      userId: widget.userId,
                                      userName: widget.authService.user?.displayName ?? widget.authService.userEmail?.split('@')[0] ?? 'User',
                                      authService: widget.authService,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _checkTicketAndTable(); // Refresh
                                }
                              },
                              icon: const Icon(Icons.table_bar),
                              label: const Text('Book VIP Table'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF88),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00FF88),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00FF88),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Table Booked',
                                        style: TextStyle(
                                          color: Color(0xFF00FF88),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Table ${_bookedTable!.tableNumber} - ${_bookedTable!.location}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.event.hasMenu)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TableMenuScreen(
                                        event: widget.event,
                                        table: _bookedTable!,
                                        userId: widget.userId,
                                        userName: widget.authService.user?.displayName ?? widget.authService.userEmail?.split('@')[0] ?? 'User',
                                        authService: widget.authService,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.restaurant_menu),
                                label: const Text('View Menu & Order'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FF88),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Organizer Management Section (only visible to organizer)
                    if (widget.event.creatorId == widget.userId) ...[
                      const Text(
                        'Event Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.event.hasTableBooking)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TableManagementScreen(event: widget.event),
                                ),
                              );
                            },
                            icon: const Icon(Icons.table_bar),
                            label: const Text('Manage VIP Tables'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1F2E),
                              foregroundColor: const Color(0xFF00FF88),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF00FF88),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.event.hasMenu)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuManagementScreen(event: widget.event),
                                ),
                              );
                            },
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Manage Menu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1F2E),
                              foregroundColor: const Color(0xFF00FF88),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF00FF88),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final result = await showPurchaseTicketDialog(
                  context,
                  widget.event,
                  widget.userId,
                  widget.authService,
                );
                
                // Always refresh ticket status after dialog closes
                if (mounted) {
                  await _checkTicketAndTable();
                  setState(() {}); // Force UI rebuild
                }
                
                // If ticket purchased and event has table booking, offer to book table
                if (result == true && widget.event.hasTableBooking && context.mounted) {
                  final shouldBookTable = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1F2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.table_bar, color: Color(0xFF00FF88)),
                          SizedBox(width: 12),
                          Text(
                            'Book a Table?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Would you like to reserve a VIP table for this event?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Later'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF88),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Yes, Book Table'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldBookTable == true && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TableBookingScreen(
                          event: widget.event,
                          userId: widget.userId,
                          userName: widget.authService.user?.displayName ?? widget.authService.userEmail?.split('@')[0] ?? 'User',
                          authService: widget.authService,
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.event.ticketPrice != null
                        ? 'Buy Ticket - \$${widget.event.ticketPrice!.toStringAsFixed(2)}'
                        : 'Get Free Ticket',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00FF88), size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
