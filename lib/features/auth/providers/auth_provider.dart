import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../data/auth_repository.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current User Provider - tracks the current authenticated user's app data
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) return null;

  // Get user data from Firestore
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserData(user.uid);
});

// Auth Controller Provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return AuthController(authRepository);
  },
);

// Auth State
class AuthState {
  final bool isLoading;
  final String? error;
  final AppUser? user;

  const AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, AppUser? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// Auth Controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState());

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.signInWithEmailPassword(
        email,
        password,
      );
      if (user != null && !user.isActive) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Your account has been deactivated. Please contact an administrator.',
        );
        await _authRepository.signOut();
        return;
      }

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create new user (Admin only)
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.createUserAccount(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      state = state.copyWith(isLoading: false);
      return user != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update user role (Admin only)
  Future<bool> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _authRepository.updateUserRole(uid, newRole);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Toggle user status (Admin only)
  Future<bool> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _authRepository.toggleUserStatus(uid, isActive);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// All Users Provider (Admin only)
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getAllUsers();
});

// User Role Check Providers
final canCreateOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canCreateOrders ?? false;
});

final canApproveOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canApproveOrders ?? false;
});

final canViewKitchenQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canViewKitchenQueue ?? false;
});

final canViewBarQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canViewBarQueue ?? false;
});

final canManageUsersProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canManageUsers ?? false;
});

final canManageProductsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canManageProducts ?? false;
});

final canViewReportsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canViewReports ?? false;
});

final canProcessPaymentsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.canProcessPayments ?? false;
});
