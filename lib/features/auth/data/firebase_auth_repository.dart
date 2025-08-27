import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/firebase_auth_service.dart';
import '../../../shared/services/firebase_database_service.dart';
import '../../../shared/services/firebase_service.dart';

class FirebaseAuthRepository {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  AppUser? _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  AppUser? get currentUser => _currentUser;

  Future<void> initialize() async {
    try {
      // Ensure Firebase service is initialized first
      await FirebaseService.ensureInitialized();
      
      FirebaseAuthService.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _loadCurrentUser(user.uid);
        } else {
          _currentUser = null;
          _authStateController.add(null);
        }
      });

      final currentUser = FirebaseAuthService.getCurrentUser();
      if (currentUser != null) {
        await _loadCurrentUser(currentUser.uid);
      }
    } catch (e) {
      Logger.error(
        'Failed to initialize Firebase Auth Repository',
        error: e,
        tag: 'FirebaseAuthRepository',
      );
      // Don't rethrow - allow app to continue with limited functionality
    }
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      Logger.info(
        'Fast loading user profile for: $userId',
        tag: 'FirebaseAuthRepository',
      );

      // Add timeout for database operations
      final userDoc = await _dbService
          .getUser(userId)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              Logger.warning(
                'Database timeout, creating temporary user profile',
                tag: 'FirebaseAuthRepository',
              );
              return null;
            },
          );

      if (userDoc != null) {
        Logger.info(
          'Found user profile: ${userDoc.name}',
          tag: 'FirebaseAuthRepository',
        );
        _currentUser = userDoc.copyWith(updatedAt: DateTime.now());
        _authStateController.add(_currentUser);
      } else {
        Logger.warning(
          'No user document found, using Firebase auth data',
          tag: 'FirebaseAuthRepository',
        );
        // Don't block login flow - create a temporary user and sync later
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          _currentUser = AppUser(
            id: userId,
            email: authUser.email ?? 'unknown@primepos.com',
            name:
                authUser.displayName ??
                authUser.email?.split('@').first ??
                'User',
            role: UserRole.waiter,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _authStateController.add(_currentUser);

          // Try to create user profile in background
          _dbService.createUser(_currentUser!).catchError((e) {
            Logger.warning(
              'Background user sync failed',
              error: e,
              tag: 'FirebaseAuthRepository',
            );
          });
        } else {
          throw Exception('Authentication state inconsistent');
        }
      }
    } catch (e) {
      Logger.error(
        'Failed to load current user',
        error: e,
        tag: 'FirebaseAuthRepository',
      );
      _currentUser = null;
      _authStateController.add(null);
      rethrow;
    }
  }

  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    Logger.info('Attempting login for: $email', tag: 'FirebaseAuthRepository');

    try {
      // Add null check and validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      
      final user = await FirebaseAuthService.signInWithEmailPassword(
        email,
        password,
      );

      if (user != null && !user.isActive) {
        Logger.warning('Account is deactivated', tag: 'FirebaseAuthRepository');
        await signOut();
        throw Exception(
          'Your account has been deactivated. Please contact an administrator.',
        );
      }

      Logger.info(
        'Login successful for: ${user?.name}',
        tag: 'FirebaseAuthRepository',
      );
      _currentUser = user;
      _authStateController.add(_currentUser);
      return user;
    } catch (e) {
      Logger.error('Login error', error: e, tag: 'FirebaseAuthRepository');

      if (e is FirebaseAuthException) {
        Logger.debug(
          'Firebase error - Code: ${e.code}, Message: ${e.message}',
          tag: 'FirebaseAuthRepository',
        );
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address');
          case 'wrong-password':
            throw Exception('Invalid password');
          case 'invalid-email':
            throw Exception('Invalid email address');
          case 'user-disabled':
            throw Exception('This account has been disabled');
          case 'too-many-requests':
            throw Exception('Too many login attempts. Please try again later.');
          default:
            throw Exception('Login failed: ${e.message}');
        }
      } else {
        throw Exception('Login failed: ${e.toString()}');
      }
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    Logger.info('Attempting Google sign in', tag: 'FirebaseAuthRepository');

    try {
      final user = await FirebaseAuthService.signInWithGoogle();

      if (user != null && !user.isActive) {
        Logger.warning('Account is deactivated', tag: 'FirebaseAuthRepository');
        await signOut();
        throw Exception(
          'Your account has been deactivated. Please contact an administrator.',
        );
      }

      Logger.info(
        'Google login successful for: ${user?.name}',
        tag: 'FirebaseAuthRepository',
      );
      _currentUser = user;
      _authStateController.add(_currentUser);
      return user;
    } catch (e) {
      Logger.error(
        'Google login error',
        error: e,
        tag: 'FirebaseAuthRepository',
      );
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  Future<AppUser?> createUserWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    Logger.info('Creating new user: $email', tag: 'FirebaseAuthRepository');

    try {
      final user = await FirebaseAuthService.createUserWithEmailPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      Logger.info(
        'User created successfully: ${user?.name}',
        tag: 'FirebaseAuthRepository',
      );
      _currentUser = user;
      _authStateController.add(_currentUser);
      return user;
    } catch (e) {
      Logger.error(
        'User creation error',
        error: e,
        tag: 'FirebaseAuthRepository',
      );

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('An account with this email already exists');
          case 'weak-password':
            throw Exception('Password is too weak');
          case 'invalid-email':
            throw Exception('Invalid email address');
          default:
            throw Exception('Failed to create user: ${e.message}');
        }
      } else {
        throw Exception('Failed to create user: ${e.toString()}');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuthService.signOut();
      _currentUser = null;
      _authStateController.add(null);
      Logger.info('Signed out successfully', tag: 'FirebaseAuthRepository');
    } catch (e) {
      Logger.error(
        'Error during sign out',
        error: e,
        tag: 'FirebaseAuthRepository',
      );
    }
  }

  Future<bool> isAvailable() async {
    try {
      return FirebaseAuthService.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  /// Get user data by ID for role verification
  Future<AppUser?> getUser(String userId) async {
    try {
      Logger.info('Fetching user data for: $userId', tag: 'FirebaseAuthRepository');
      
      final userDoc = await _dbService
          .getUser(userId)
          .timeout(const Duration(seconds: 10));
      
      return userDoc;
    } catch (e) {
      Logger.error(
        'Failed to get user data for: $userId',
        error: e,
        tag: 'FirebaseAuthRepository',
      );
      return null;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
