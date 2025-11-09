import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  
  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  User? _user;
  String? _userRole;
  String? _userEmail;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userRole => _userRole;
  String? get userEmail => _userEmail;
  bool get isDeveloper => _userRole == 'developer';
  bool get isUser => _userRole == 'user';

  AuthService() {
    // Only set up Firebase listeners if Firebase is initialized
    if (_isFirebaseInitialized) {
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        
        // Listen to authentication state changes
        _auth!.authStateChanges().listen((User? user) async {
          _user = user;
          if (user != null) {
            _userEmail = user.email;
            await _loadUserData(user.uid);
          } else {
            _userRole = null;
            _userEmail = null;
          }
          notifyListeners();
        });
      } catch (e) {
        debugPrint('Firebase not available: $e');
      }
    } else {
      debugPrint('Firebase is not initialized. Running in demo mode.');
      // In demo mode, user stays logged out
      _user = null;
      _userRole = null;
      _userEmail = null;
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    if (!_isFirebaseInitialized || _firestore == null) return;
    
    try {
      final docSnapshot = await _firestore!.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _userRole = data?['role'] as String?;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Register a new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'user' or 'developer'
  }) async {
    if (!_isFirebaseInitialized || _auth == null || _firestore == null) {
      throw Exception('Firebase is not configured. Please set up Firebase first.');
    }
    
    try {
      // Create user with email and password
      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Update user display name
        await user.updateDisplayName(name);
        await user.reload();

        // Save user data to Firestore
        await _firestore!.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Load user data
        await _loadUserData(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isFirebaseInitialized || _auth == null) {
      throw Exception('Firebase is not configured. Please set up Firebase first.');
    }
    
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // User data will be loaded automatically by authStateChanges listener
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!_isFirebaseInitialized || _auth == null) {
      _user = null;
      _userRole = null;
      _userEmail = null;
      notifyListeners();
      return;
    }
    
    try {
      await _auth!.signOut();
      _user = null;
      _userRole = null;
      _userEmail = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_user == null || !_isFirebaseInitialized || _firestore == null) return null;

    try {
      final docSnapshot =
          await _firestore!.collection('users').doc(_user!.uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
}
