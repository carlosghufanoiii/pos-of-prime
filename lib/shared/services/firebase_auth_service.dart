import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'firebase_service.dart';
import 'firebase_database_service.dart';

class FirebaseAuthService {
  static FirebaseAuth get _auth {
    try {
      return FirebaseService.auth;
    } catch (e) {
      throw StateError('Firebase Auth not available: $e');
    }
  }
  
  static GoogleSignIn get _googleSignIn {
    try {
      return FirebaseService.googleSignIn;
    } catch (e) {
      throw StateError('Google Sign In not available: $e');
    }
  }
  static final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  static Future<AppUser?> signInWithGoogle() async {
    try {
      await FirebaseService.ensureInitialized();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        AppUser? appUser = await _dbService.getUser(user.uid);

        if (appUser == null) {
          // 🔧 ADMIN OVERRIDE: Make admin@primepos.com admin by default
          final userRole = (user.email == 'admin@primepos.com') 
              ? UserRole.admin 
              : UserRole.waiter;
              
          appUser = AppUser(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            role: userRole, // Admin for admin@primepos.com, waiter for others
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _dbService.createUser(appUser);
        } else if (user.email == 'admin@primepos.com' && appUser.role != UserRole.admin) {
          // 🔧 ADMIN OVERRIDE: Update existing admin@primepos.com to admin role
          Logger.info(
            'Updating admin@primepos.com from ${appUser.role} to admin role',
            tag: 'FirebaseAuthService',
          );
          appUser = appUser.copyWith(
            role: UserRole.admin,
            updatedAt: DateTime.now(),
          );
          await _dbService.updateUser(appUser);
        }

        return appUser;
      }

      return null;
    } catch (e) {
      Logger.error(
        'Google sign-in error',
        error: e,
        tag: 'FirebaseAuthService',
      );
      return null;
    }
  }

  static Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.ensureInitialized();
      
      // Enable persistence for offline support
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (persistenceError) {
        Logger.warning(
          'Failed to set persistence, continuing without',
          error: persistenceError,
          tag: 'FirebaseAuthService',
        );
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        Logger.info(
          'Fast loading user profile for: ${user.uid}',
          tag: 'FirebaseAuthService',
        );

        // Try to get user from cache first, then fallback to database
        AppUser? appUser;
        try {
          appUser = await _dbService.getUser(user.uid);
        } catch (e) {
          Logger.warning(
            'Database lookup failed, using cached user data',
            error: e,
            tag: 'FirebaseAuthService',
          );
          // Create temporary user from Firebase auth data
          // 🔧 ADMIN OVERRIDE: Make admin@primepos.com admin by default
          final userRole = (user.email == 'admin@primepos.com') 
              ? UserRole.admin 
              : UserRole.waiter;
              
          appUser = AppUser(
            id: user.uid,
            email: user.email ?? email,
            name: user.displayName ?? user.email?.split('@').first ?? 'User',
            role: userRole, // Admin for admin@primepos.com, waiter for others
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        if (appUser == null) {
          Logger.info(
            'Creating new user profile for: ${user.email}',
            tag: 'FirebaseAuthService',
          );
          // 🔧 ADMIN OVERRIDE: Make admin@primepos.com admin by default
          final userRole = (user.email == 'admin@primepos.com') 
              ? UserRole.admin 
              : UserRole.waiter;
              
          appUser = AppUser(
            id: user.uid,
            email: user.email ?? email,
            name: user.displayName ?? user.email?.split('@').first ?? 'User',
            role: userRole, // Admin for admin@primepos.com, waiter for others
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          // Create user in background to avoid blocking login
          _dbService.createUser(appUser).catchError((e) {
            Logger.warning(
              'Background user creation failed',
              error: e,
              tag: 'FirebaseAuthService',
            );
          });
          Logger.info(
            'User profile created in background',
            tag: 'FirebaseAuthService',
          );
        } else if (user.email == 'admin@primepos.com' && appUser.role != UserRole.admin) {
          // 🔧 ADMIN OVERRIDE: Update existing admin@primepos.com to admin role
          Logger.info(
            'Updating admin@primepos.com from ${appUser.role} to admin role',
            tag: 'FirebaseAuthService',
          );
          appUser = appUser.copyWith(
            role: UserRole.admin,
            updatedAt: DateTime.now(),
          );
          // Update user in background to avoid blocking login
          _dbService.updateUser(appUser).catchError((e) {
            Logger.warning(
              'Background user update failed',
              error: e,
              tag: 'FirebaseAuthService',
            );
          });
        }

        return appUser;
      }

      return null;
    } catch (e) {
      Logger.error('Email sign-in error', error: e, tag: 'FirebaseAuthService');
      rethrow; // Re-throw to preserve original error details
    }
  }

  static Future<AppUser?> createUserWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      await FirebaseService.ensureInitialized();

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        // 🔧 ADMIN OVERRIDE: Make admin@primepos.com admin by default
        final finalRole = (email == 'admin@primepos.com') 
            ? UserRole.admin 
            : role;

        final appUser = AppUser(
          id: user.uid,
          email: email,
          name: name,
          role: finalRole, // Admin override for admin@primepos.com
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _dbService.createUser(appUser);
        return appUser;
      }

      return null;
    } catch (e) {
      Logger.error('User creation error', error: e, tag: 'FirebaseAuthService');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      Logger.error('Sign-out error', error: e, tag: 'FirebaseAuthService');
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  static bool get isSignedIn => _auth.currentUser != null;
}
