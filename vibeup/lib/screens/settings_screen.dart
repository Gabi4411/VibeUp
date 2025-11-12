import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;

  const SettingsScreen({super.key, required this.authService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = widget.authService.user?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _nameController.text = data?['name'] ?? '';
            _notificationsEnabled = data?['notificationsEnabled'] ?? true;
            _darkModeEnabled = data?['darkModeEnabled'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.authService.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'name': _nameController.text.trim()},
        );

        if (mounted) {
          _showSuccess('Name updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update name: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _showSuccess('Password updated successfully');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'wrong-password') {
          _showError('Current password is incorrect');
        } else if (e.code == 'requires-recent-login') {
          _showError(
            'Please log out and log in again before changing password',
          );
        } else {
          _showError('Failed to update password: ${e.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update password: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.authService.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'notificationsEnabled': _notificationsEnabled,
              'darkModeEnabled': _darkModeEnabled,
            });

        if (mounted) {
          _showSuccess('Settings updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00FF88),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Information Section
              _buildSectionTitle('Account Information'),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.email_outlined,
                label: 'Email',
                value: widget.authService.userEmail ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: widget.authService.userRole?.toUpperCase() ?? 'N/A',
              ),
              const SizedBox(height: 24),

              // Update Name Section
              _buildSectionTitle('Update Name'),
              const SizedBox(height: 16),
              _buildNameSection(),
              const SizedBox(height: 24),

              // Change Password Section
              _buildSectionTitle('Change Password'),
              const SizedBox(height: 16),
              _buildPasswordSection(),
              const SizedBox(height: 24),

              // App Settings Section
              _buildSectionTitle('App Settings'),
              const SizedBox(height: 16),
              _buildAppSettingsSection(),
              const SizedBox(height: 24),

              // Account Actions Section
              _buildSectionTitle('Account Actions'),
              const SizedBox(height: 16),
              _buildAccountActionsSection(),
            ],
          ),
        ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00FF88), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Display Name',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.person, color: Color(0xFF00FF88)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateName,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text(
                    'Update Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Current Password',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Enter current password',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF00FF88)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Enter new password',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.lock, color: Color(0xFF00FF88)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Re-enter new password',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.lock_clock, color: Color(0xFF00FF88)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Receive notifications about events',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _notificationsEnabled,
            activeThumbColor: const Color(0xFF00FF88),
            activeTrackColor: const Color(0xFF00FF88).withValues(alpha: 0.5),
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _updateSettings();
            },
          ),
          // Dark mode toggle removed; app uses static styling
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await widget.authService.signOut();
                if (mounted) {
                  navigator.pop();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Logout', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00FF88),
              side: const BorderSide(color: Color(0xFF00FF88)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1F2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Account deletion is not yet implemented',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete Account', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
