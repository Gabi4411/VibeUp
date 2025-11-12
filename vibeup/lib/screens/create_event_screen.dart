import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final Event? existingEvent; // For editing

  const CreateEventScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.existingEvent,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _ticketPriceController;
  late TextEditingController _ticketPriceVIPController;

  // State variables
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Music';
  List<String> _selectedTags = [];
  bool _isPublic = true;
  bool _isLoading = false;

  // Available categories
  final List<String> _categories = [
    'Music',
    'Nightlife',
    'Arts',
    'Sports',
    'Food',
    'Conference',
    'Workshop',
    'Festival',
    'Other',
  ];

  // Available tags
  final List<String> _availableTags = [
    'Outdoor',
    'Indoor',
    'Live Music',
    '21+',
    'Family Friendly',
    'Free Food',
    'Networking',
    'VIP Available',
    'Limited Seats',
    'Early Bird',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing event data if editing
    _nameController = TextEditingController(
      text: widget.existingEvent?.name ?? '',
    );
    _locationController = TextEditingController(
      text: widget.existingEvent?.location ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingEvent?.description ?? '',
    );
    _ticketPriceController = TextEditingController(
      text: widget.existingEvent?.ticketPrice?.toString() ?? '',
    );
    _ticketPriceVIPController = TextEditingController(
      text: widget.existingEvent?.ticketPriceVIP ?? '',
    );

    if (widget.existingEvent != null) {
      _selectedDate = widget.existingEvent!.dateTime;
      _selectedCategory = widget.existingEvent!.category;
      _selectedTags = List.from(widget.existingEvent!.tags);
      _isPublic = widget.existingEvent!.isPublic;
      // Parse time from existing event
      final timeParts = widget.existingEvent!.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 18;
        final minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketPriceController.dispose();
    _ticketPriceVIPController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FF88),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FF88),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tag'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Format time as string
      final timeString = _selectedTime.format(context);

      // Parse ticket prices
      final ticketPrice = _ticketPriceController.text.isEmpty
          ? null
          : double.tryParse(_ticketPriceController.text);

      // Create event object
      final event = Event(
        id: widget.existingEvent?.id ?? '',
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: eventDateTime,
        time: timeString,
        category: _selectedCategory,
        tags: _selectedTags,
        isPublic: _isPublic,
        ticketPrice: ticketPrice,
        ticketPriceVIP: _ticketPriceVIPController.text.trim().isEmpty
            ? null
            : _ticketPriceVIPController.text.trim(),
        creatorId: widget.userId,
        creatorName: widget.userName,
        attendanceCount: widget.existingEvent?.attendanceCount ?? 0,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        updatedAt: widget.existingEvent != null ? DateTime.now() : null,
      );

      if (widget.existingEvent != null) {
        // Update existing event
        await _eventService.updateEvent(widget.existingEvent!.id, event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully!'),
              backgroundColor: Color(0xFF00FF88),
            ),
          );
        }
      } else {
        // Create new event
        await _eventService.createEvent(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully!'),
              backgroundColor: Color(0xFF00FF88),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingEvent != null ? 'Edit Event' : 'Create New Event',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.event, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter event name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description, color: Colors.white70),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF00FF88),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF00FF88),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                const Text(
                  'Category *',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1F2E),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                const Text(
                  'Tags *',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return InkWell(
                      onTap: () => _toggleTag(tag),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00FF88)
                              : const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00FF88)
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Ticket Prices
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ticketPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Ticket Price (GA)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1F2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Free',
                          hintStyle: const TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ticketPriceVIPController,
                        decoration: InputDecoration(
                          labelText: 'VIP Price',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.star,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1F2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Optional',
                          hintStyle: const TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Public/Private Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public, color: Colors.white70),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Public Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Anyone can see and join this event',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF00FF88),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEvent,
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
                            widget.existingEvent != null
                                ? 'Update Event'
                                : 'Create Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
