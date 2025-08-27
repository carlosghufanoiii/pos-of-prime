import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/services/user_management_service.dart';
import '../../../shared/services/analytics_service.dart';

// User management providers - Stream for real-time updates
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return UserManagementService.getAllUsersStream();
});

final usersByRoleProvider = FutureProvider.family<List<AppUser>, String>((
  ref,
  role,
) async {
  return await UserManagementService.getUsersByRole(role);
});

// Analytics providers
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return await AnalyticsService.getDashboardStats();
});

final salesAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return await AnalyticsService.getSalesAnalytics();
});

final systemStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await AnalyticsService.getSystemStats();
});

// Recent activities provider
final recentActivitiesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await AnalyticsService.getRecentActivities();
});

// User management state
final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
      return UserManagementNotifier();
    });

class UserManagementState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const UserManagementState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  UserManagementState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  UserManagementNotifier() : super(const UserManagementState());

  Future<bool> createUser(AppUser user, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await UserManagementService.createUser(user, password);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'User created successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create user',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(AppUser user) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await UserManagementService.updateUser(user);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'User updated successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update user',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await UserManagementService.deleteUser(userId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'User deleted successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete user',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await UserManagementService.toggleUserStatus(
        userId,
        isActive,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: isActive ? 'User activated' : 'User deactivated',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update user status',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String userId, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await UserManagementService.resetPassword(
        userId,
        newPassword,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Password reset successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to reset password',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
