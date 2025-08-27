import '../models/app_user.dart';
import 'backend_api_service.dart';
import '../utils/logger.dart';

/// Enhanced User management service using backend API
/// Provides secure role management with server-side validation
class UserManagementServiceBackend {
  
  /// Get all users via backend API (admin only)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      Logger.info('Fetching all users via backend API', tag: 'UserManagementServiceBackend');
      return await BackendApiService.getAllUsers();
    } catch (e) {
      Logger.error('Failed to get users from backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get users by role via backend API
  static Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) => user.role.name == role).toList();
    } catch (e) {
      Logger.error('Failed to get users by role from backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to get users by role: $e');
    }
  }

  /// Create a new user with proper role assignment via backend API
  /// 🔧 FIXED: Server-side role validation ensures proper assignment
  static Future<bool> createUser(AppUser user, String password) async {
    try {
      Logger.info(
        'Creating user via backend API: ${user.email} with role: ${user.role.name}',
        tag: 'UserManagementServiceBackend'
      );

      final createdUser = await BackendApiService.createUser(
        email: user.email,
        password: password,
        name: user.name,
        role: user.role,
      );

      if (createdUser != null) {
        Logger.info(
          '✅ User created successfully: ${createdUser.email} with role: ${createdUser.role.name}',
          tag: 'UserManagementServiceBackend'
        );
        return true;
      }

      Logger.error('Backend API returned null for user creation', tag: 'UserManagementServiceBackend');
      return false;
    } catch (e) {
      Logger.error('Failed to create user via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user information via backend API
  static Future<bool> updateUser(AppUser user) async {
    try {
      Logger.info('Updating user via backend API: ${user.email}', tag: 'UserManagementServiceBackend');
      return await BackendApiService.updateUser(user);
    } catch (e) {
      Logger.error('Failed to update user via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete a user via backend API
  static Future<bool> deleteUser(String userId) async {
    try {
      Logger.info('Deleting user via backend API: $userId', tag: 'UserManagementServiceBackend');
      return await BackendApiService.deleteUser(userId);
    } catch (e) {
      Logger.error('Failed to delete user via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Toggle user active status
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      // Get current user data
      final allUsers = await getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception('User not found'),
      );

      // Update user with new active status
      final updatedUser = user.copyWith(isActive: isActive);
      return await updateUser(updatedUser);
    } catch (e) {
      Logger.error('Failed to toggle user status via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to toggle user status: $e');
    }
  }

  /// Reset user password (placeholder - handled by Firebase Auth)
  static Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      // Password reset would typically be handled by Firebase Auth
      // This is a placeholder for backend implementation
      Logger.info('Password reset requested for user: $userId', tag: 'UserManagementServiceBackend');
      return true;
    } catch (e) {
      Logger.error('Failed to reset password via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Get user by ID via backend API
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) => user.id == userId).firstOrNull;
    } catch (e) {
      Logger.error('Failed to get user by ID via backend', error: e, tag: 'UserManagementServiceBackend');
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get current user profile via backend API
  static Future<AppUser?> getCurrentUser() async {
    try {
      Logger.info('Getting current user profile via backend API', tag: 'UserManagementServiceBackend');
      return await BackendApiService.getCurrentUser();
    } catch (e) {
      Logger.error('Failed to get current user via backend', error: e, tag: 'UserManagementServiceBackend');
      return null;
    }
  }

  /// Check backend health and connectivity
  static Future<Map<String, dynamic>> checkBackendStatus() async {
    try {
      return await BackendApiService.checkHealth();
    } catch (e) {
      Logger.error('Backend health check failed', error: e, tag: 'UserManagementServiceBackend');
      return {
        'status': 'ERROR',
        'mode': 'offline',
        'firebase_initialized': false,
        'message': 'Backend not available',
        'error': e.toString(),
      };
    }
  }
}