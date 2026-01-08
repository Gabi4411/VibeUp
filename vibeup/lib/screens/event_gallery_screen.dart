import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_model.dart';
import '../models/event_photo_model.dart';
import '../services/photo_service.dart';

class EventGalleryScreen extends StatefulWidget {
  final Event event;
  final String userId;
  final String userName;
  final bool isOrganizer;

  const EventGalleryScreen({
    super.key,
    required this.event,
    required this.userId,
    required this.userName,
    required this.isOrganizer,
  });

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _filter = 'all'; // 'all', 'organizer', 'attendees'

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Read file as bytes for web compatibility
      final bytes = await image.readAsBytes();

      await _photoService.uploadPhoto(
        eventId: widget.event.id,
        userId: widget.userId,
        userName: widget.userName,
        file: kIsWeb ? bytes : await image.path, // Uint8List for web, path for mobile
        isOrganizerPhoto: widget.isOrganizer,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.event.name} - Gallery',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF00FF88)),
            onPressed: _isUploading ? null : _pickAndUploadImage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: const Color(0xFF1A1F2E),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                _buildFilterTab('All Photos', 'all'),
                const SizedBox(width: 12),
                _buildFilterTab('By Organizer', 'organizer'),
                const SizedBox(width: 12),
                _buildFilterTab('By Attendees', 'attendees'),
              ],
            ),
          ),
          
          // Photos grid
          Expanded(
            child: StreamBuilder<List<EventPhoto>>(
              stream: _photoService.getEventPhotos(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF88)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading photos',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
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
                  );
                }

                final allPhotos = snapshot.data ?? [];
                
                // Filter photos based on selected filter
                final filteredPhotos = _filter == 'all'
                    ? allPhotos
                    : _filter == 'organizer'
                        ? allPhotos.where((p) => p.isOrganizerPhoto).toList()
                        : allPhotos.where((p) => !p.isOrganizerPhoto).toList();

                if (filteredPhotos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'all'
                              ? 'No photos yet'
                              : _filter == 'organizer'
                                  ? 'No organizer photos yet'
                                  : 'No attendee photos yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + icon to upload a photo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredPhotos.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoCard(filteredPhotos[index]);
                  },
                );
              },
            ),
          ),
          
          // Upload indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1F2E),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00FF88)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Uploading photo...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF131722),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(EventPhoto photo) {
    return GestureDetector(
      onTap: () {
        _showPhotoDetails(photo);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photo.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFF1A1F2E),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FF88),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1A1F2E),
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),
          if (photo.isOrganizerPhoto)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ORG',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoDetails(EventPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1F2E),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: const Color(0xFF131722),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        photo.isOrganizerPhoto ? Icons.verified : Icons.person,
                        color: const Color(0xFF00FF88),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          photo.uploaderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploaded ${_formatDate(photo.uploadedAt)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (photo.uploaderId == widget.userId) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _photoService.deletePhoto(
                              photo.id,
                              photo.imageUrl,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo deleted'),
                                  backgroundColor: Color(0xFF00FF88),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}