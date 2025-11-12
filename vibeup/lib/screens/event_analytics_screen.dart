import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class EventAnalyticsScreen extends StatefulWidget {
  final Event event;

  const EventAnalyticsScreen({super.key, required this.event});

  @override
  State<EventAnalyticsScreen> createState() => _EventAnalyticsScreenState();
}

class _EventAnalyticsScreenState extends State<EventAnalyticsScreen> {
  final TicketService _ticketService = TicketService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Analytics',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ticket>>(
          stream: _ticketService.getEventTickets(widget.event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF88)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final tickets = snapshot.data ?? [];
            final totalRevenue = tickets.fold<double>(
              0.0,
              (sum, ticket) => sum + ticket.price,
            );
            final gaTickets = tickets.where((t) => t.ticketType == 'GA').length;
            final vipTickets = tickets
                .where((t) => t.ticketType == 'VIP')
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Info Card
                  _buildEventInfoCard(),
                  const SizedBox(height: 24),

                  // Stats Overview
                  _buildSectionTitle('Overview'),
                  const SizedBox(height: 16),
                  _buildStatsGrid(
                    tickets.length,
                    totalRevenue,
                    gaTickets,
                    vipTickets,
                  ),
                  const SizedBox(height: 24),

                  // Revenue Breakdown
                  if (tickets.isNotEmpty) ...[
                    _buildSectionTitle('Revenue Breakdown'),
                    const SizedBox(height: 16),
                    _buildRevenueCard(tickets, totalRevenue),
                    const SizedBox(height: 24),
                  ],

                  // Attendance List
                  _buildSectionTitle('Attendance List (${tickets.length})'),
                  const SizedBox(height: 16),
                  if (tickets.isEmpty)
                    _buildEmptyAttendanceList()
                  else
                    ..._buildAttendanceList(tickets),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.event.isPublic
                      ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.event.isPublic
                        ? const Color(0xFF00FF88)
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.event.isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    color: widget.event.isPublic
                        ? const Color(0xFF00FF88)
                        : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.event.location,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${widget.event.formattedDate} ${widget.event.formattedDay} • ${widget.event.time}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                widget.event.category,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsGrid(
    int totalTickets,
    double totalRevenue,
    int gaTickets,
    int vipTickets,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.confirmation_number,
                label: 'Total Tickets',
                value: totalTickets.toString(),
                color: const Color(0xFF00FF88),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                label: 'Total Revenue',
                value: '\$${totalRevenue.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.person,
                label: 'GA Tickets',
                value: gaTickets.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: 'VIP Tickets',
                value: vipTickets.toString(),
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(List<Ticket> tickets, double totalRevenue) {
    final gaRevenue = tickets
        .where((t) => t.ticketType == 'GA')
        .fold<double>(0.0, (sum, ticket) => sum + ticket.price);
    final vipRevenue = tickets
        .where((t) => t.ticketType == 'VIP')
        .fold<double>(0.0, (sum, ticket) => sum + ticket.price);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'General Admission',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '\$${gaRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VIP Tickets',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '\$${vipRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Revenue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAttendanceList() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No attendees yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ticket purchases will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceList(List<Ticket> tickets) {
    return tickets.map((ticket) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF00FF88),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Ticket info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User ${ticket.userId.substring(0, 8)}...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ticket.ticketType == 'VIP'
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticket.ticketType,
                          style: TextStyle(
                            color: ticket.ticketType == 'VIP'
                                ? Colors.amber
                                : Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(ticket.purchasedAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Text(
              ticket.price > 0
                  ? '\$${ticket.price.toStringAsFixed(2)}'
                  : 'Free',
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
