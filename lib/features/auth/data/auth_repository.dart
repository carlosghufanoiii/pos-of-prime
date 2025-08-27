import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with email and password
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        // Update last login time
        await _updateLastLogin(result.user!.uid);
        return await getUserData(result.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user profile in Firestore
  Future<AppUser?> _createUserProfile(User user, UserRole role) async {
    try {
      final appUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(appUser.toJson());

      return appUser;
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'lastLoginAt': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      // Non-critical error, don't throw
      debugPrint('Failed to update last login: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Create new user account (Admin only)
  Future<AppUser?> createUserAccount({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);

        // Create user profile
        final appUser = await _createUserProfile(result.user!, role);

        // Sign out the newly created user (admin remains signed in)
        await _firebaseAuth.signOut();

        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user role (Admin only)
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'role': newRole.name},
      );
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Toggle user active status (Admin only)
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'isActive': isActive},
      );
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Get all users (Admin only)
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList(),
        );
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
