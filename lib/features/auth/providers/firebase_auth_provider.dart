import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../data/firebase_auth_repository.dart';

// Firebase Auth Repository Provider
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  final repository = FirebaseAuthRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

// Auth State Provider
final firebaseAuthStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(firebaseAuthRepositoryProvider);
  return authRepository.authStateChanges;
});

// Auth Controller Provider
final firebaseAuthControllerProvider =
    StateNotifierProvider<FirebaseAuthController, AuthState>((ref) {
      final authRepository = ref.watch(firebaseAuthRepositoryProvider);
      return FirebaseAuthController(authRepository);
    });

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
class FirebaseAuthController extends StateNotifier<AuthState> {
  final FirebaseAuthRepository _authRepository;

  FirebaseAuthController(this._authRepository) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authRepository.initialize();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize authentication: ${e.toString()}',
      );
    }
  }

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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.signInWithGoogle();
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

  Future<void> createUserWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.createUserWithEmailPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Current User Provider
final firebaseCurrentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.valueOrNull;
});

// User Role Check Providers
final firebaseCanCreateOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canCreateOrders ?? false;
});

final firebaseCanApproveOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canApproveOrders ?? false;
});

final firebaseCanViewKitchenQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canViewKitchenQueue ?? false;
});

final firebaseCanViewBarQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canViewBarQueue ?? false;
});

final firebaseCanManageUsersProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canManageUsers ?? false;
});

final firebaseCanManageProductsProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canManageProducts ?? false;
});

final firebaseCanViewReportsProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canViewReports ?? false;
});

final firebaseCanProcessPaymentsProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseCurrentUserProvider);
  return user?.role.canProcessPayments ?? false;
});
