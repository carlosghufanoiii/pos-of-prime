import 'package:prime_pos/shared/utils/logger.dart';
import '../models/app_user.dart';
import '../services/firebase_database_service.dart';
import '../services/firebase_auth_service.dart';

class FirebaseUserRepository {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  Future<void> createUser(AppUser user) async {
    await _dbService.createUser(user);
  }

  Future<AppUser?> getUser(String userId) async {
    return await _dbService.getUser(userId);
  }

  Future<void> updateUser(AppUser user) async {
    await _dbService.updateUser(user);
  }

  Future<void> deleteUser(String userId) async {
    await _dbService.deleteUser(userId);
  }

  Future<List<AppUser>> getAllUsers() async {
    return await _dbService.getAllUsers();
  }

  Stream<List<AppUser>> getUsersStream() {
    return _dbService.getUsersStream();
  }

  // Business logic methods for service compatibility
  Future<List<AppUser>> getUsersByRole(String role) async {
    final users = await getAllUsers();
    return users.where((user) => user.role.name == role).toList();
  }

  Future<bool> createUserWithResult(AppUser user, String password) async {
    try {
      Logger.info(
        '🚀 Fast-creating user: ${user.email}',
        tag: 'FirebaseUserRepository',
      );

      // Create user with Firebase Authentication - this is already optimized
      final result = await FirebaseAuthService.createUserWithEmailPassword(
        email: user.email,
        password: password,
        name: user.name,
        role: user.role,
      );

      if (result != null) {
        Logger.info(
          '✅ User created successfully with Auth ID: ${result.id}',
          tag: 'FirebaseUserRepository',
        );
        return true;
      } else {
        Logger.error(
          '❌ Failed to create user with Firebase Auth',
          tag: 'FirebaseUserRepository',
        );
        return false;
      }
    } catch (e) {
      Logger.error(
        '💥 Error creating user with auth',
        error: e,
        tag: 'FirebaseUserRepository',
      );
      return false;
    }
  }

  Future<bool> updateUserWithResult(AppUser user) async {
    try {
      await _dbService.updateUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUserWithResult(String userId) async {
    try {
      await _dbService.deleteUser(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final user = await getUser(userId);
      if (user != null) {
        final updatedUser = user.copyWith(isActive: isActive);
        await updateUser(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String userId, String newPassword) async {
    // Firebase Auth handles password reset through email
    // This would typically use Firebase Auth methods
    try {
      // Placeholder - actual implementation would use Firebase Auth
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AppUser?> getUserById(String userId) async {
    return await getUser(userId);
  }
}
