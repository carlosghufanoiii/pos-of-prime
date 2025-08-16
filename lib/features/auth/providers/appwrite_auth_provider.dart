import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/app_user.dart';
import '../data/appwrite_auth_repository.dart';

// Appwrite Auth Repository Provider
final appwriteAuthRepositoryProvider = Provider<AppwriteAuthRepository>((ref) {
  final repository = AppwriteAuthRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

// Auth State Provider
final appwriteAuthStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(appwriteAuthRepositoryProvider);
  return authRepository.authStateChanges;
});

// Auth Controller Provider
final appwriteAuthControllerProvider = StateNotifierProvider<AppwriteAuthController, AuthState>((ref) {
  final authRepository = ref.watch(appwriteAuthRepositoryProvider);
  return AppwriteAuthController(authRepository);
});

// Auth State
class AuthState {
  final bool isLoading;
  final String? error;
  final AppUser? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    AppUser? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// Auth Controller
class AppwriteAuthController extends StateNotifier<AuthState> {
  final AppwriteAuthRepository _authRepository;

  AppwriteAuthController(this._authRepository) : super(const AuthState()) {
    // Initialize Appwrite and check current session
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authRepository.initialize();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize authentication: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.signInWithEmailPassword(email, password);
      if (user != null && !user.isActive) {
        state = state.copyWith(
          isLoading: false, 
          error: 'Your account has been deactivated. Please contact an administrator.',
        );
        await _authRepository.signOut();
        return;
      }
      
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null && !user.isActive) {
        state = state.copyWith(
          isLoading: false, 
          error: 'Your account has been deactivated. Please contact an administrator.',
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

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Current User Provider
final appwriteCurrentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(appwriteAuthStateProvider);
  return authState.valueOrNull;
});

// User Role Check Providers
final appwriteCanCreateOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canCreateOrders ?? false;
});

final appwriteCanApproveOrdersProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canApproveOrders ?? false;
});

final appwriteCanViewKitchenQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canViewKitchenQueue ?? false;
});

final appwriteCanViewBarQueueProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canViewBarQueue ?? false;
});

final appwriteCanManageUsersProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canManageUsers ?? false;
});

final appwriteCanManageProductsProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canManageProducts ?? false;
});

final appwriteCanViewReportsProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canViewReports ?? false;
});

final appwriteCanProcessPaymentsProvider = Provider<bool>((ref) {
  final user = ref.watch(appwriteCurrentUserProvider);
  return user?.role.canProcessPayments ?? false;
});