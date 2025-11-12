import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/ticket_service.dart';

class PurchaseTicketDialog extends StatefulWidget {
  final Event event;
  final String userId;

  const PurchaseTicketDialog({
    super.key,
    required this.event,
    required this.userId,
  });

  @override
  State<PurchaseTicketDialog> createState() => _PurchaseTicketDialogState();
}

class _PurchaseTicketDialogState extends State<PurchaseTicketDialog> {
  final TicketService _ticketService = TicketService();
  String _selectedTicketType = 'GA';
  bool _isLoading = false;
  bool _alreadyHasTicket = false;
  bool _checkingTicket = true;

  @override
  void initState() {
    super.initState();
    _checkExistingTicket();
  }

  Future<void> _checkExistingTicket() async {
    try {
      final hasTicket = await _ticketService.hasTicketForEvent(
        widget.userId,
        widget.event.id,
      );
      if (mounted) {
        setState(() {
          _alreadyHasTicket = hasTicket;
          _checkingTicket = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingTicket = false;
        });
      }
    }
  }

  double get _selectedPrice {
    if (_selectedTicketType == 'VIP' && widget.event.ticketPriceVIP != null) {
      return double.tryParse(widget.event.ticketPriceVIP!) ?? 0.0;
    }
    return widget.event.ticketPrice ?? 0.0;
  }

  Future<void> _purchaseTicket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ticketService.purchaseTicket(
        event: widget.event,
        userId: widget.userId,
        ticketType: _selectedTicketType,
        price: _selectedPrice,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket purchased successfully!'),
            backgroundColor: Color(0xFF00FF88),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVIP = widget.event.ticketPriceVIP != null;
    final isFree = widget.event.ticketPrice == null && !hasVIP;

    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _checkingTicket
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00FF88)),
                  SizedBox(height: 16),
                  Text(
                    'Checking availability...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              )
            : _alreadyHasTicket
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Already Purchased',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFF00FF88),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You already have a ticket for this event',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check your Tickets tab to view it',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF00FF88),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Purchase Ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Event Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.event.formattedDate} ${widget.event.formattedDay} • ${widget.event.time}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ticket Type Selection (if VIP available)
                  if (!isFree && hasVIP) ...[
                    const Text(
                      'Select Ticket Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTicketTypeOption(
                      'GA',
                      'General Admission',
                      widget.event.ticketPrice!,
                      Icons.confirmation_number,
                    ),
                    const SizedBox(height: 12),
                    _buildTicketTypeOption(
                      'VIP',
                      'VIP Access',
                      double.tryParse(widget.event.ticketPriceVIP!) ?? 0.0,
                      Icons.star,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Price Display
                  if (!isFree) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00FF88),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_selectedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00FF88),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Purchase Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _purchaseTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Text(
                              isFree ? 'Get Ticket' : 'Confirm Purchase',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTicketTypeOption(
    String value,
    String label,
    double price,
    IconData icon,
  ) {
    final isSelected = _selectedTicketType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTicketType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF88).withValues(alpha: 0.2)
              : const Color(0xFF131722),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF88) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00FF88) : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF00FF88) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the dialog
Future<bool?> showPurchaseTicketDialog(
  BuildContext context,
  Event event,
  String userId,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => PurchaseTicketDialog(event: event, userId: userId),
  );
}
