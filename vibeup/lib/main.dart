import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/ticket_service.dart';
import 'models/event_model.dart';
import 'models/ticket_model.dart';
import 'screens/create_event_screen.dart';
import 'screens/event_details_screen.dart';
import 'screens/event_analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/event_gallery_screen.dart';
import 'widgets/purchase_ticket_dialog.dart';

// Firebase Options Import
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await _initializeFirebase();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Firebase initialization error: $e');
      debugPrint('');
      debugPrint('📋 To set up Firebase properly:');
      debugPrint(
        '1. Install FlutterFire CLI: dart pub global activate flutterfire_cli',
      );
      debugPrint('2. Run: flutterfire configure');
      debugPrint(
        '3. Uncomment the import and initialization code in main.dart',
      );
      debugPrint('');
      debugPrint('⚠️  The app will continue but authentication will not work.');
    }
  }

  runApp(const VibeUpApp());
}

Future<void> _initializeFirebase() async {
  try {
    // OPTION 1: Use firebase_options.dart (Recommended - after running flutterfire configure)
    // Uncomment the following lines after running "flutterfire configure":

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // OPTION 2: Initialize without options (for web with manual Firebase config in index.html)
    // This will work if Firebase is configured in web/index.html
    //await Firebase.initializeApp();

    if (kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase exception: ${e.message}');
    }
    rethrow;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization failed: $e');
    }
    rethrow;
  }
}

class VibeUpApp extends StatelessWidget {
  const VibeUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131722),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF00FF88),
          surface: Color(0xFF1A1F2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF1A1F2E),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper to check authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
    // Wait a bit for Firebase to initialize and check auth state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
      );
    }

    return _AuthProvider(
      authService: _authService,
      child: _authService.isAuthenticated
          ? const MainScreen()
          : const AuthScreen(),
    );
  }
}

// Helper widget to provide AuthService to children and rebuild on changes
class _AuthProvider extends StatefulWidget {
  final AuthService authService;
  final Widget child;

  const _AuthProvider({required this.authService, required this.child});

  @override
  State<_AuthProvider> createState() => _AuthProviderState();
}

class _AuthProviderState extends State<_AuthProvider> {
  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedAuthProvider(
      authService: widget.authService,
      child: widget.child,
    );
  }
}

// InheritedWidget that provides AuthService
class _InheritedAuthProvider extends InheritedWidget {
  final AuthService authService;

  const _InheritedAuthProvider({
    required this.authService,
    required super.child,
  });

  static AuthService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_InheritedAuthProvider>();
    if (provider == null) {
      throw Exception('AuthProvider not found');
    }
    return provider.authService;
  }

  @override
  bool updateShouldNotify(_InheritedAuthProvider oldWidget) {
    return authService != oldWidget.authService;
  }
}

// Authentication Screen (Login/Register)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = _InheritedAuthProvider.of(context);

      if (_isLogin) {
        // Sign in
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Register
        await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _selectedRole!, // 'user' or 'developer'
        );
      }

      // Clear form on success
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _selectedRole = null;
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final logoSize = isSmallScreen ? 60.0 : 80.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),
                // Logo/App Name
                Icon(
                  Icons.event,
                  size: logoSize,
                  color: const Color(0xFF00FF88),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'VibeUp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 28 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back!' : 'Create your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 40),
                // Name field (only for register)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.person,
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
                      if (!_isLogin && (value == null || value.isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Role selection (only for register)
                if (!_isLogin) ...[
                  const Text(
                    'Select your role:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleButton('User', Icons.person, 'user'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleButton(
                          'Developer',
                          Icons.code,
                          'developer',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // Submit button
                SizedBox(
                  height: 50, // Minimum touch target size for mobile
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
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
                            _isLogin ? 'Login' : 'Register',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Toggle between login and register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _selectedRole = null;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Don\'t have an account? Register'
                        : 'Already have an account? Login',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
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

  Widget _buildRoleButton(String label, IconData icon, String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF88) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TicketsScreen(),
    const ChatScreen(),
    const MyEventsGalleryScreen(),
    const ProfileScreen(),
  ];

  List<NavigationDestination> _buildNavigationDestinations(
    AuthService authService,
  ) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.explore, color: Color(0xFF00FF88)),
        label: 'Discover',
      ),
      const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.confirmation_number, color: Color(0xFF00FF88)),
        label: 'Tickets',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline, color: Colors.white70),
        selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF00FF88)),
        label: 'Chat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.photo_library_outlined, color: Colors.white70),
        selectedIcon: Icon(Icons.photo_library, color: Color(0xFF00FF88)),
        label: 'Gallery',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline, color: Colors.white70),
        selectedIcon: Icon(Icons.person, color: Color(0xFF00FF88)),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1F2E),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: const Color(0xFF00FF88).withValues(alpha: 0.2),
        destinations: _buildNavigationDestinations(authService),
      ),
    );
  }
}

// Discover Screen (Main Home Page)
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String? _selectedCategory; // null means "All"
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listen to auth service changes (for balance updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = _InheritedAuthProvider.of(context);
      authService.addListener(_onAuthServiceChanged);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Remove listener
    try {
      final authService = _InheritedAuthProvider.of(context);
      authService.removeListener(_onAuthServiceChanged);
    } catch (e) {
      // Context might not be available
    }
    super.dispose();
  }

  void _onAuthServiceChanged() {
    if (mounted) {
      setState(() {
        // Rebuild to show updated balance
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(authService),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      _searchQuery.isNotEmpty
                          ? 'Search Results'
                          : (_selectedCategory == null
                                ? 'All Events'
                                : '$_selectedCategory Events'),
                    ),
                    const SizedBox(height: 16),
                    // Stream builder to display events from Firebase
                    StreamBuilder<List<Event>>(
                      stream: _selectedCategory == null
                          ? _eventService.getPublicEvents()
                          : _eventService.getEventsByCategory(
                              _selectedCategory!,
                            ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                    'Error loading events',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final allEvents = snapshot.data ?? [];

                        // Filter events by search query
                        final events = _searchQuery.isEmpty
                            ? allEvents
                            : allEvents
                                  .where(
                                    (event) => event.name
                                        .toLowerCase()
                                        .contains(_searchQuery),
                                  )
                                  .toList();

                        if (events.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No events available yet'
                                        : 'No events found matching "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: events
                              .map((event) => _buildEventCard(context, event))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8), // Bottom padding for scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      color: const Color(0xFF1A1F2E),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'VibeUp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Balance display
          GestureDetector(
            onTap: () => _showAddMoneyDialog(context, authService),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF88), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF00FF88),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '\$${authService.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF00FF88),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              // Navigate to settings screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(authService: authService),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search events by name',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    // Category filters - horizontally scrollable
    return SizedBox(
      height: 44, // Fixed height for consistent layout
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', Icons.apps, _selectedCategory == null),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Music',
            Icons.music_note,
            _selectedCategory == 'Music',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Nightlife',
            Icons.nightlife,
            _selectedCategory == 'Nightlife',
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Arts', Icons.palette, _selectedCategory == 'Arts'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Sports',
            Icons.sports_soccer,
            _selectedCategory == 'Sports',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Food',
            Icons.restaurant,
            _selectedCategory == 'Food',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Conference',
            Icons.business,
            _selectedCategory == 'Conference',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Workshop',
            Icons.school,
            _selectedCategory == 'Workshop',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Festival',
            Icons.celebration,
            _selectedCategory == 'Festival',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Other',
            Icons.category,
            _selectedCategory == 'Other',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData? icon, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          // If "All" is selected, set category to null
          _selectedCategory = label == 'All' ? null : label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF88) : const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date block
              Container(
                width: 55,
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.formattedDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.formattedDay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.time,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: event.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44, // Minimum touch target
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to event details screen
                      final authService = _InheritedAuthProvider.of(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(
                            event: event,
                            userId: authService.user?.uid ?? '',
                            authService: authService,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44, // Minimum touch target
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show purchase ticket dialog
                      final authService = _InheritedAuthProvider.of(context);
                      await showPurchaseTicketDialog(
                        context,
                        event,
                        authService.user?.uid ?? '',
                        authService,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Buy Ticket',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${event.attendanceCount} going',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AddMoneyDialog(authService: authService),
    );
  }
}

// Add Money Dialog
class AddMoneyDialog extends StatefulWidget {
  final AuthService authService;

  const AddMoneyDialog({super.key, required this.authService});

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  double _selectedAmount = 50.0;
  bool _isLoading = false;
  final List<double> _quickAmounts = [10, 25, 50, 100, 200, 500];

  Future<void> _addMoney() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.addMoney(_selectedAmount);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added \$${_selectedAmount.toStringAsFixed(2)} to your balance!',
            ),
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
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
                    Icons.account_balance_wallet,
                    color: Color(0xFF00FF88),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Add Money',
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
            // Current balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Balance:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '\$${widget.authService.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick amount selection
            const Text(
              'Select Amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                          : const Color(0xFF131722),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00FF88)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00FF88)
                            : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // New balance preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Balance:',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '\$${(widget.authService.balance + _selectedAmount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Add money button
            ElevatedButton(
              onPressed: _isLoading ? null : _addMoney,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
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
                  : Text(
                      'Add \$${_selectedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens for other navigation tabs
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ticket>>(
          stream: _ticketService.getUserTickets(authService.user?.uid ?? ''),
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
                        'Error loading tickets',
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

            if (tickets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No tickets yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase tickets to see them here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(tickets[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return GestureDetector(
      onTap: () {
        final authService = _InheritedAuthProvider.of(context);
        _showTicketQRCode(ticket, authService);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Tap to view QR code hint
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, color: Color(0xFF00FF88), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to view QR Code',
                    style: TextStyle(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Main ticket content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date block
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ticket.formattedDate,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.formattedDay,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ticket.eventLocation,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.eventTime,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00FF88,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF00FF88),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    ticket.ticketType == 'VIP'
                                        ? Icons.star
                                        : Icons.confirmation_number,
                                    size: 14,
                                    color: const Color(0xFF00FF88),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ticket.ticketType,
                                    style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              ticket.price > 0
                                  ? '\$${ticket.price.toStringAsFixed(2)}'
                                  : 'Free',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Delete button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(ticket);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Cancel Attendance'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketQRCode(Ticket ticket, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) =>
          TicketQRCodeDialog(ticket: ticket, authService: authService),
    );
  }

  void _showDeleteConfirmation(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Attendance',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel your attendance for "${ticket.eventName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Ticket',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _ticketService.deleteTicket(ticket.id, ticket.eventId);
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Ticket cancelled successfully'),
                      backgroundColor: Color(0xFF00FF88),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Cancel Ticket',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Ticket QR Code Dialog
class TicketQRCodeDialog extends StatelessWidget {
  final Ticket ticket;
  final AuthService authService;

  const TicketQRCodeDialog({
    super.key,
    required this.ticket,
    required this.authService,
  });

  String _generateQRData() {
    // Generate a JSON string with ticket and user information
    return '''
{
  "ticketId": "${ticket.id}",
  "eventId": "${ticket.eventId}",
  "eventName": "${ticket.eventName}",
  "eventLocation": "${ticket.eventLocation}",
  "eventDateTime": "${ticket.eventDateTime.toIso8601String()}",
  "ticketType": "${ticket.ticketType}",
  "userId": "${ticket.userId}",
  "userEmail": "${authService.userEmail ?? 'N/A'}",
  "purchasedAt": "${ticket.purchasedAt.toIso8601String()}",
  "price": ${ticket.price}
}''';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final qrSize = isMobile ? 200.0 : 250.0;

    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9, // Max 90% of screen height
          maxWidth: isMobile ? screenWidth * 0.9 : 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (fixed at top)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: Color(0xFF00FF88),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Event Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.eventName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ticket.eventLocation,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${ticket.formattedDate} ${ticket.formattedDay} • ${ticket.eventTime}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00FF88,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00FF88),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ticket.ticketType == 'VIP'
                                      ? Icons.star
                                      : Icons.confirmation_number,
                                  size: 14,
                                  color: const Color(0xFF00FF88),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ticket.ticketType,
                                  style: const TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: _generateQRData(),
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ticket Holder',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Color(0xFF00FF88),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authService.userEmail ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number,
                                size: 16,
                                color: Color(0xFF00FF88),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ID: ${ticket.id.substring(0, 8)}...',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF00FF88),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Show this QR code at the event entrance',
                              style: TextStyle(
                                color: const Color(
                                  0xFF00FF88,
                                ).withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TicketService _ticketService = TicketService();
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Chats', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ticket>>(
          stream: _ticketService.getUserTickets(authService.user?.uid ?? ''),
          builder: (context, ticketSnapshot) {
            if (ticketSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF88)),
              );
            }

            if (ticketSnapshot.hasError) {
              return Center(
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
                      'Error loading your events',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final tickets = ticketSnapshot.data ?? [];

            if (tickets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No event chats yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase tickets to events to join their chat rooms',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Get unique event IDs from tickets
            final eventIds = tickets.map((t) => t.eventId).toSet().toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventIds.length,
              itemBuilder: (context, index) {
                return _buildEventChatCard(
                  context,
                  eventIds[index],
                  authService,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventChatCard(
    BuildContext context,
    String eventId,
    AuthService authService,
  ) {
    return FutureBuilder<Event?>(
      future: _eventService.getEventById(eventId),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF88),
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (!eventSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final event = eventSnapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                      event: event,
                      userId: authService.user?.uid ?? '',
                      userName: authService.userEmail?.split('@')[0] ?? 'User',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Event icon/avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Color(0xFF00FF88),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Event info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.attendanceCount} members',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.formattedDate} ${event.formattedDay}',
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
                    // Arrow icon
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Developer Screen with developer dashboard content
class DeveloperScreen extends StatefulWidget {
  final bool isDeveloper;

  const DeveloperScreen({super.key, required this.isDeveloper});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    if (!widget.isDeveloper) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Developer Access Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please register as a developer to access this section',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Developer Dashboard'),
              const SizedBox(height: 16),
              _buildOrganizerActions(context, authService),
              const SizedBox(height: 24),
              _buildSectionTitle('My Events'),
              const SizedBox(height: 16),
              // Stream builder to display developer's events
              StreamBuilder<List<Event>>(
                stream: _eventService.getDeveloperEvents(
                  authService.user?.uid ?? '',
                ),
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
                              'Error loading events',
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

                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events created yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "New Event" to create your first event',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: events
                        .map(
                          (event) => _buildDeveloperEventCard(
                            context,
                            event,
                            authService,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
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
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOrganizerActions(BuildContext context, AuthService authService) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.add_circle_outline,
            label: 'New Event',
            onTap: () async {
              // Navigate to create event screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventScreen(
                    userId: authService.user?.uid ?? '',
                    userName: authService.userEmail ?? 'Developer',
                  ),
                ),
              );

              // Refresh the list if event was created
              if (result == true && mounted) {
                setState(() {});
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            onTap: () {
              _showAnalyticsEventSelector(context, authService);
            },
          ),
        ),
      ],
    );
  }

  void _showAnalyticsEventSelector(
    BuildContext context,
    AuthService authService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Event for Analytics',
          style: TextStyle(color: Colors.white),
        ),
        content: StreamBuilder<List<Event>>(
          stream: _eventService.getDeveloperEvents(authService.user?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FF88)),
                ),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return const Text(
                'No events available. Create an event first.',
                style: TextStyle(color: Colors.white70),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Color(0xFF00FF88),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${event.attendanceCount} attending',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventAnalyticsScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00FF88), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperEventCard(
    BuildContext context,
    Event event,
    AuthService authService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with event name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                  color: event.isPublic
                      ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: event.isPublic
                        ? const Color(0xFF00FF88)
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  event.isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    color: event.isPublic
                        ? const Color(0xFF00FF88)
                        : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location, date and time
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
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
              const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${event.formattedDate} ${event.formattedDay} • ${event.time}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${event.attendanceCount} attending',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.category, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                event.category,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Navigate to edit event screen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateEventScreen(
                          userId: authService.user?.uid ?? '',
                          userName: authService.userEmail ?? 'Developer',
                          existingEvent: event,
                        ),
                      ),
                    );

                    // Refresh the list if event was updated
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to analytics screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventAnalyticsScreen(event: event),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Analytics'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF00FF88)),
                    foregroundColor: Color(0xFF00FF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Show delete confirmation
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1F2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Delete Event',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
                          style: const TextStyle(color: Colors.white70),
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
                            onPressed: () async {
                              try {
                                await _eventService.deleteEvent(event.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Event deleted successfully',
                                      ),
                                      backgroundColor: Color(0xFF00FF88),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
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
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Home Screen - wraps DiscoverScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiscoverScreen();
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: authService.isDeveloper 
          ? const DeveloperScreen(isDeveloper: true)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'User Profile',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authService.userEmail ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(authService: authService),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00FF88),
                        side: const BorderSide(color: Color(0xFF00FF88)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// My Events Gallery Screen - shows user's attended events
class MyEventsGalleryScreen extends StatefulWidget {
  const MyEventsGalleryScreen({super.key});

  @override
  State<MyEventsGalleryScreen> createState() => _MyEventsGalleryScreenState();
}

class _MyEventsGalleryScreenState extends State<MyEventsGalleryScreen> {
  final TicketService _ticketService = TicketService();
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final authService = _InheritedAuthProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events Gallery', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F2E),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ticket>>(
          stream: _ticketService.getUserTickets(authService.user?.uid ?? ''),
          builder: (context, ticketSnapshot) {
            if (ticketSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF88)),
              );
            }

            if (ticketSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading events',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            final tickets = ticketSnapshot.data ?? [];

            if (tickets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No event photos yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase tickets to events to view and share photos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final eventIds = tickets.map((t) => t.eventId).toSet().toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventIds.length,
              itemBuilder: (context, index) {
                return _buildEventGalleryCard(
                  context,
                  eventIds[index],
                  authService,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventGalleryCard(
    BuildContext context,
    String eventId,
    AuthService authService,
  ) {
    return FutureBuilder<Event?>(
      future: _eventService.getEventById(eventId),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF88),
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (!eventSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final event = eventSnapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Check if user is organizer
                final isOrganizer = event.creatorId == authService.user?.uid;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventGalleryScreen(
                      event: event,
                      userId: authService.user?.uid ?? '',
                      userName: authService.userEmail?.split('@')[0] ?? 'User',
                      isOrganizer: isOrganizer,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Event icon/avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Color(0xFF00FF88),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.formattedDate} ${event.formattedDay}',
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
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
