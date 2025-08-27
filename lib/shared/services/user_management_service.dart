import '../models/app_user.dart';
import '../repositories/firebase_user_repository.dart';

/// User management service for admin operations
/// Handles user creation, updates, deletion, and role management
class UserManagementService {
  static final FirebaseUserRepository _repository = FirebaseUserRepository();

  /// Get all users
  static Future<List<AppUser>> getAllUsers() async {
    try {
      return await _repository.getAllUsers();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get all users as stream for real-time updates
  static Stream<List<AppUser>> getAllUsersStream() {
    return _repository.getUsersStream();
  }

  /// Get users by role
  static Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      return await _repository.getUsersByRole(role);
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  /// Create a new user
  static Future<bool> createUser(AppUser user, String password) async {
    try {
      return await _repository.createUserWithResult(user, password);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user information
  static Future<bool> updateUser(AppUser user) async {
    try {
      return await _repository.updateUserWithResult(user);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete a user
  static Future<bool> deleteUser(String userId) async {
    try {
      return await _repository.deleteUserWithResult(userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Toggle user active status
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      return await _repository.toggleUserStatus(userId, isActive);
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

  /// Reset user password
  static Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      return await _repository.resetPassword(userId, newPassword);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Get user by ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      return await _repository.getUserById(userId);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
}
