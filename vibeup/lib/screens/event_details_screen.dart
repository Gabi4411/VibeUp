import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../widgets/purchase_ticket_dialog.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;
  final String userId;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.userId,
  });

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
                      event.name,
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
                        color: event.isPublic
                            ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: event.isPublic
                              ? const Color(0xFF00FF88)
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        event.isPublic ? 'Public Event' : 'Private Event',
                        style: TextStyle(
                          color: event.isPublic
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
                        ).format(event.dateTime),
                        event.time,
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location Card
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: [event.location],
                    ),
                    const SizedBox(height: 16),

                    // Category & Tags
                    _buildInfoCard(
                      icon: Icons.category,
                      title: 'Category',
                      content: [event.category],
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (event.tags.isNotEmpty) ...[
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
                        children: event.tags.map((tag) {
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
                      content: [event.description],
                    ),
                    const SizedBox(height: 16),

                    // Organizer Info
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Organized by',
                      content: [event.creatorName],
                    ),
                    const SizedBox(height: 16),

                    // Attendance
                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Attendance',
                      content: ['${event.attendanceCount} people attending'],
                    ),
                    const SizedBox(height: 16),

                    // Ticket Pricing (if available)
                    if (event.ticketPrice != null ||
                        event.ticketPriceVIP != null) ...[
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
                            if (event.ticketPrice != null)
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
                                    '\$${event.ticketPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            if (event.ticketPrice != null &&
                                event.ticketPriceVIP != null)
                              const Divider(height: 24, color: Colors.white24),
                            if (event.ticketPriceVIP != null)
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
                                    '\$${event.ticketPriceVIP!}',
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
                await showPurchaseTicketDialog(context, event, userId);
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
                    event.ticketPrice != null
                        ? 'Buy Ticket - \$${event.ticketPrice!.toStringAsFixed(2)}'
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
