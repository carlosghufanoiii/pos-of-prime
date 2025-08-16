import 'dart:async';
import 'package:appwrite/appwrite.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/appwrite_database_service.dart';

class AppwriteAuthRepository {
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  Account? _account;
  Client? _client;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  AppUser? get currentUser => _currentUser;

  /// Initialize Appwrite client and account
  Future<void> initialize() async {
    try {
      await AppwriteDatabaseService.initialize();
      
      _client = Client()
          .setEndpoint('http://localhost/v1')
          .setProject('prime-pos');

      _account = Account(_client!);
      
      // Check if user is already logged in
      await _checkCurrentSession();
    } catch (e) {
      print('Failed to initialize Appwrite Auth: $e');
    }
  }

  /// Check if there's an active session
  Future<void> _checkCurrentSession() async {
    try {
      final account = await _account!.get();
      if (account.$id.isNotEmpty) {
        await _loadCurrentUser();
      }
    } catch (e) {
      // No active session
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  /// Load current user data from Appwrite
  Future<void> _loadCurrentUser() async {
    try {
      // Get account info
      print('📧 Getting account info...');
      final account = await _account!.get();
      print('📧 Account email: ${account.email}');
      
      // Find user document in database by email
      print('🔍 Searching for user in database...');
      final users = await AppwriteDatabaseService.getUsers();
      print('📋 Found ${users.length} users in database');
      
      final userDoc = users.where((u) => u.email == account.email).firstOrNull;
      
      if (userDoc != null) {
        print('✅ Found user profile: ${userDoc.displayName}');
        _currentUser = userDoc.copyWith(
          lastLoginAt: DateTime.now(),
        );
        _authStateController.add(_currentUser);
      } else {
        print('❌ No user document found for email: ${account.email}');
        print('Available users:');
        for (final user in users) {
          print('  - ${user.email} (${user.displayName})');
        }
        throw Exception('User account found but no profile data. Please contact administrator.');
      }
    } catch (e) {
      print('❌ Failed to load current user: $e');
      _currentUser = null;
      _authStateController.add(null);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmailPassword(String email, String password) async {
    print('🔐 Attempting login for: $email');
    
    try {
      // Initialize if not already done
      if (_account == null) {
        print('⚡ Initializing Appwrite...');
        await initialize();
      }

      // First, always clear any existing sessions to avoid conflicts
      try {
        await _account!.deleteSessions();
        print('🧹 Cleared existing sessions');
      } catch (e) {
        print('ℹ️ No existing sessions to clear');
      }

      // Create session with Appwrite
      print('🚀 Creating new session...');
      await _account!.createEmailSession(email: email, password: password);
      print('✅ Session created successfully');
      
      // Load user data from database
      print('👤 Loading user profile...');
      await _loadCurrentUser();
      
      // Check if account is active
      if (_currentUser != null && !_currentUser!.isActive) {
        print('❌ Account is deactivated');
        await signOut();
        throw Exception('Your account has been deactivated. Please contact an administrator.');
      }
      
      print('✅ Login successful for: ${_currentUser?.displayName}');
      return _currentUser;
    } catch (e) {
      print('❌ Login error: $e');
      
      // Handle Appwrite specific errors
      if (e is AppwriteException) {
        print('🔍 Appwrite error - Code: ${e.code}, Type: ${e.type}, Message: ${e.message}');
        switch (e.code) {
          case 401:
            throw Exception('Invalid email or password');
          case 429:
            throw Exception('Too many login attempts. Please try again later.');
          default:
            throw Exception('Login failed: ${e.message}');
        }
      } else {
        throw Exception('Login failed: ${e.toString()}');
      }
    }
  }


  /// Sign out
  Future<void> signOut() async {
    try {
      if (_account != null) {
        await _account!.deleteSessions();
      }
    } catch (e) {
      print('Error during sign out: $e');
    } finally {
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  /// Get user role from database
  UserRole _parseUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'waiter':
        return UserRole.waiter;
      case 'cashier':
        return UserRole.cashier;
      case 'kitchen':
        return UserRole.kitchen;
      case 'bartender':
        return UserRole.bartender;
      default:
        return UserRole.waiter; // Default fallback
    }
  }

  /// Check if service is available
  Future<bool> isAvailable() async {
    try {
      if (_account == null) {
        await initialize();
      }
      return _account != null;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}