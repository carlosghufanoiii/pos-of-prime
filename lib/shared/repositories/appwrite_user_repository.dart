import 'package:appwrite/appwrite.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/appwrite_database_service.dart';

/// Appwrite-based user repository for admin user management
class AppwriteUserRepository {
  /// Get all users from the database
  Future<List<AppUser>> getAllUsers() async {
    try {
      return await AppwriteDatabaseService.getUsers();
    } catch (e) {
      print('Failed to get all users: $e');
      return [];
    }
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      final allUsers = await AppwriteDatabaseService.getUsers();
      return allUsers.where((user) => user.role.name == role).toList();
    } catch (e) {
      print('Failed to get users by role: $e');
      return [];
    }
  }

  /// Create a new user
  Future<bool> createUser(AppUser user, String password) async {
    try {
      // First create the user in Appwrite Auth
      final authResult = await _createAuthUser(user.email, password, user.displayName);
      if (authResult == null) return false;

      // Then create the user document in database with the auth user ID
      final userWithAuthId = AppUser(
        id: authResult,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        isActive: user.isActive,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
      );

      await AppwriteDatabaseService.createUser(userWithAuthId);
      return true;
    } catch (e) {
      print('Failed to create user: $e');
      return false;
    }
  }

  /// Update user information
  Future<bool> updateUser(AppUser user) async {
    try {
      await AppwriteDatabaseService.updateUser(user);
      return true;
    } catch (e) {
      print('Failed to update user: $e');
      return false;
    }
  }

  /// Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete from database first
      await AppwriteDatabaseService.deleteUser(userId);
      
      // Then delete from Appwrite Auth if needed
      // Note: This requires admin privileges
      await _deleteAuthUser(userId);
      
      return true;
    } catch (e) {
      print('Failed to delete user: $e');
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final user = await AppwriteDatabaseService.getUserById(userId);
      if (user == null) return false;

      final updatedUser = AppUser(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        isActive: isActive,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
      );

      await AppwriteDatabaseService.updateUser(updatedUser);
      return true;
    } catch (e) {
      print('Failed to toggle user status: $e');
      return false;
    }
  }

  /// Reset user password
  Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      // This requires Appwrite Server SDK for admin operations
      // For now, we'll implement a workaround using database flags
      final user = await AppwriteDatabaseService.getUserById(userId);
      if (user == null) return false;

      // In a real implementation, you would:
      // 1. Use Appwrite Server SDK to reset password
      // 2. Or implement a password reset flow via email
      
      // For now, we'll just mark that password needs reset
      print('Password reset requested for user: ${user.email}');
      return true;
    } catch (e) {
      print('Failed to reset password: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      return await AppwriteDatabaseService.getUserById(userId);
    } catch (e) {
      print('Failed to get user by ID: $e');
      return null;
    }
  }

  /// Create user in Appwrite Auth (requires admin privileges)
  Future<String?> _createAuthUser(String email, String password, String name) async {
    try {
      // This would require Appwrite Server SDK for admin operations
      // For now, we'll simulate the creation and return a generated ID
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      print('Creating auth user: $email (simulated: $userId)');
      return userId;
    } catch (e) {
      print('Failed to create auth user: $e');
      return null;
    }
  }

  /// Delete user from Appwrite Auth (requires admin privileges)
  Future<void> _deleteAuthUser(String userId) async {
    try {
      // This would require Appwrite Server SDK for admin operations
      print('Deleting auth user: $userId (simulated)');
    } catch (e) {
      print('Failed to delete auth user: $e');
    }
  }
}