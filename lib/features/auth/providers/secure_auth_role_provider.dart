import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/utils/logger.dart';
import '../data/firebase_auth_repository.dart';

/// Secure storage keys for auth data
class AuthStorageKeys {
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String isActive = 'is_active';
  static const String lastLoginTime = 'last_login_time';
}

/// Authentication and authorization state
enum AuthRoleState {
  initial,           // App just started
  loading,          // Authentication in progress
  roleResolving,    // User authenticated, resolving role
  authenticated,    // User authenticated with role resolved
  unauthenticated,  // No user or authentication failed
  error,            // Error during authentication/role resolution
}

/// Secure authentication and role management
class SecureAuthRoleNotifier extends StateNotifier<AuthRoleData> {
  final FirebaseAuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;

  SecureAuthRoleNotifier(
    this._authRepository, 
    this._secureStorage,
  ) : super(const AuthRoleData()) {
    _initialize();
  }

  /// Initialize authentication state on app start - OPTIMIZED FOR SPEED
  Future<void> _initialize() async {
    Logger.info('⚡ Fast initializing secure authentication', tag: 'SecureAuthRole');
    
    // Start with loading but immediately check cache
    state = state.copyWith(authState: AuthRoleState.loading);

    // PRIORITY 1: Check cached user first (instant)
    final cachedUser = await _loadCachedUser();
    if (cachedUser != null) {
      Logger.info('⚡ INSTANT LOGIN: Using cached user ${cachedUser.email}', tag: 'SecureAuthRole');
      
      // Set authenticated state immediately - user can start using app
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: cachedUser,
        error: null,
      );
      
      // Verify cached user in background (non-blocking)
      _verifyAndRefreshUser(cachedUser).catchError((e) {
        Logger.warning('Background verification failed: $e', tag: 'SecureAuthRole');
      });
      return;
    }

    // PRIORITY 2: No cached user, try Firebase with reduced timeout
    try {
      await _authRepository.initialize().timeout(
        const Duration(seconds: 5), // Reduced from 10 seconds
        onTimeout: () {
          throw Exception('Fast initialization timeout');
        },
      );
      
      Logger.info('🔍 No cached user, showing login screen', tag: 'SecureAuthRole');
      state = state.copyWith(authState: AuthRoleState.unauthenticated);
      
    } catch (e) {
      Logger.info('⚡ Firebase init failed, fast-track to login: $e', tag: 'SecureAuthRole');
      
      // Don't waste time on fallbacks - go straight to login
      state = state.copyWith(
        authState: AuthRoleState.unauthenticated,
        error: null, // No error shown to user
      );
    }
  }

  /// Load cached user from secure storage
  Future<AppUser?> _loadCachedUser() async {
    try {
      final userId = await _secureStorage.read(key: AuthStorageKeys.userId);
      final userRoleString = await _secureStorage.read(key: AuthStorageKeys.userRole);
      final userName = await _secureStorage.read(key: AuthStorageKeys.userName);
      final userEmail = await _secureStorage.read(key: AuthStorageKeys.userEmail);
      final isActiveString = await _secureStorage.read(key: AuthStorageKeys.isActive);
      final lastLoginString = await _secureStorage.read(key: AuthStorageKeys.lastLoginTime);

      if (userId == null || userRoleString == null || userName == null || 
          userEmail == null || isActiveString == null) {
        return null;
      }

      // Parse cached data
      final userRole = UserRole.values.firstWhere(
        (role) => role.name == userRoleString,
        orElse: () => UserRole.waiter, // Default to least privileged role
      );
      
      final isActive = isActiveString == 'true';
      final lastLoginAt = lastLoginString != null ? DateTime.tryParse(lastLoginString) : null;

      return AppUser(
        id: userId,
        email: userEmail,
        name: userName,
        role: userRole,
        isActive: isActive,
        createdAt: DateTime.now(), // Placeholder
        updatedAt: DateTime.now(), // Placeholder
        lastLoginAt: lastLoginAt,
      );
    } catch (e) {
      Logger.error('❌ Failed to load cached user', error: e, tag: 'SecureAuthRole');
      return null;
    }
  }

  /// Verify cached user is still valid and refresh if needed
  Future<void> _verifyAndRefreshUser(AppUser cachedUser) async {
    try {
      state = state.copyWith(authState: AuthRoleState.roleResolving);

      // Check if user is still authenticated with Firebase
      final currentFirebaseUser = _authRepository.currentUser;
      
      if (currentFirebaseUser == null) {
        Logger.info('🔄 Firebase user not authenticated, clearing cache', tag: 'SecureAuthRole');
        await _clearAuthCache();
        state = state.copyWith(authState: AuthRoleState.unauthenticated);
        return;
      }

      // Try to fetch fresh user data with timeout to prevent infinite loading
      AppUser? freshUser;
      try {
        freshUser = await _authRepository.getUser(cachedUser.id).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            Logger.warning('⏰ User verification timeout, using cached data', tag: 'SecureAuthRole');
            return null;
          },
        );
      } catch (e) {
        Logger.warning('⚠️ User verification failed, using cached data: $e', tag: 'SecureAuthRole');
        freshUser = null;
      }
      
      if (freshUser == null) {
        // Use cached user if fresh data unavailable
        Logger.info('📱 Using cached user data for: ${cachedUser.email}', tag: 'SecureAuthRole');
        state = state.copyWith(
          authState: AuthRoleState.authenticated,
          user: cachedUser,
          error: null,
        );
        return;
      }

      if (!freshUser.isActive) {
        Logger.warning('⚠️ User account deactivated, signing out', tag: 'SecureAuthRole');
        await _clearAuthCache();
        await _authRepository.signOut();
        state = state.copyWith(authState: AuthRoleState.unauthenticated);
        return;
      }

      // Check if role has changed
      if (freshUser.role != cachedUser.role) {
        Logger.info('🔄 User role changed from ${cachedUser.role.name} to ${freshUser.role.name}', tag: 'SecureAuthRole');
        await _cacheUser(freshUser);
      }

      // Successfully verified and refreshed
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: freshUser,
        error: null,
      );

      Logger.info('✅ User verified: ${freshUser.email} (${freshUser.role.name})', tag: 'SecureAuthRole');

    } catch (e) {
      Logger.error('❌ Failed to verify cached user', error: e, tag: 'SecureAuthRole');
      
      // On verification failure, use cached data to prevent infinite loading
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: cachedUser,
        error: null, // Don't show error to user, just use offline mode
      );
      
      Logger.info('📱 Using offline mode for: ${cachedUser.email}', tag: 'SecureAuthRole');
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    Logger.info('🔐 Attempting login: $email', tag: 'SecureAuthRole');
    
    state = state.copyWith(
      authState: AuthRoleState.loading,
      error: null,
    );

    try {
      // FAST LOGIN: Reduced timeout for quicker response
      final user = await _authRepository.signInWithEmailPassword(email, password).timeout(
        const Duration(seconds: 8), // Reduced from 15 seconds
        onTimeout: () {
          throw Exception('Login timed out. Please try again.');
        },
      );
      
      if (user == null) {
        state = state.copyWith(
          authState: AuthRoleState.unauthenticated,
          error: 'Invalid email or password',
        );
        return;
      }

      if (!user.isActive) {
        await _authRepository.signOut();
        state = state.copyWith(
          authState: AuthRoleState.unauthenticated,
          error: 'Account is deactivated. Please contact an administrator.',
        );
        return;
      }

      // INSTANT SUCCESS: Set authenticated state immediately
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: user,
        error: null,
      );

      Logger.info('⚡ FAST LOGIN successful: ${user.email} (${user.role.name})', tag: 'SecureAuthRole');

      // Cache user in background (non-blocking)
      _cacheUser(user).catchError((cacheError) {
        Logger.warning('Background cache failed: $cacheError', tag: 'SecureAuthRole');
      });

    } catch (e) {
      Logger.error('❌ Login failed', error: e, tag: 'SecureAuthRole');
      state = state.copyWith(
        authState: AuthRoleState.unauthenticated,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    Logger.info('🔐 Attempting Google login', tag: 'SecureAuthRole');
    
    state = state.copyWith(
      authState: AuthRoleState.loading,
      error: null,
    );

    try {
      final user = await _authRepository.signInWithGoogle();
      
      if (user == null) {
        state = state.copyWith(
          authState: AuthRoleState.unauthenticated,
          error: 'Google sign-in was cancelled or failed',
        );
        return;
      }

      if (!user.isActive) {
        await _authRepository.signOut();
        state = state.copyWith(
          authState: AuthRoleState.unauthenticated,
          error: 'Account is deactivated. Please contact an administrator.',
        );
        return;
      }

      state = state.copyWith(authState: AuthRoleState.roleResolving);
      
      await _cacheUser(user);
      
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: user,
        error: null,
      );

      Logger.info('✅ Google login successful: ${user.email} (${user.role.name})', tag: 'SecureAuthRole');

    } catch (e) {
      Logger.error('❌ Google login failed', error: e, tag: 'SecureAuthRole');
      state = state.copyWith(
        authState: AuthRoleState.error,
        error: e.toString(),
      );
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    Logger.info('👋 Signing out user', tag: 'SecureAuthRole');
    
    try {
      await _authRepository.signOut();
      await _clearAuthCache();
      
      state = const AuthRoleData();
      
      Logger.info('✅ Sign out completed', tag: 'SecureAuthRole');
      
    } catch (e) {
      Logger.error('❌ Sign out failed', error: e, tag: 'SecureAuthRole');
      // Still clear local state even if Firebase signout failed
      await _clearAuthCache();
      state = const AuthRoleData();
    }
  }

  /// Cache user data securely
  Future<void> _cacheUser(AppUser user) async {
    try {
      await Future.wait([
        _secureStorage.write(key: AuthStorageKeys.userId, value: user.id),
        _secureStorage.write(key: AuthStorageKeys.userRole, value: user.role.name),
        _secureStorage.write(key: AuthStorageKeys.userName, value: user.name),
        _secureStorage.write(key: AuthStorageKeys.userEmail, value: user.email),
        _secureStorage.write(key: AuthStorageKeys.isActive, value: user.isActive.toString()),
        _secureStorage.write(key: AuthStorageKeys.lastLoginTime, value: DateTime.now().toIso8601String()),
      ]);
      
      Logger.debug('💾 User cached securely', tag: 'SecureAuthRole');
    } catch (e) {
      Logger.error('❌ Failed to cache user', error: e, tag: 'SecureAuthRole');
    }
  }

  /// Clear authentication cache
  Future<void> _clearAuthCache() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: AuthStorageKeys.userId),
        _secureStorage.delete(key: AuthStorageKeys.userRole),
        _secureStorage.delete(key: AuthStorageKeys.userName),
        _secureStorage.delete(key: AuthStorageKeys.userEmail),
        _secureStorage.delete(key: AuthStorageKeys.isActive),
        _secureStorage.delete(key: AuthStorageKeys.lastLoginTime),
      ]);
      
      Logger.debug('🗑️ Auth cache cleared', tag: 'SecureAuthRole');
    } catch (e) {
      Logger.error('❌ Failed to clear auth cache', error: e, tag: 'SecureAuthRole');
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force refresh user role from server
  Future<void> refreshUserRole() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    Logger.info('🔄 Refreshing user role', tag: 'SecureAuthRole');

    try {
      state = state.copyWith(authState: AuthRoleState.roleResolving);

      final freshUser = await _authRepository.getUser(currentUser.id);
      
      if (freshUser == null || !freshUser.isActive) {
        Logger.warning('⚠️ User no longer active during refresh', tag: 'SecureAuthRole');
        await signOut();
        return;
      }

      await _cacheUser(freshUser);
      
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        user: freshUser,
        error: null,
      );

      Logger.info('✅ User role refreshed: ${freshUser.role.name}', tag: 'SecureAuthRole');

    } catch (e) {
      Logger.error('❌ Failed to refresh user role', error: e, tag: 'SecureAuthRole');
      // Keep existing user data on refresh failure
      state = state.copyWith(
        authState: AuthRoleState.authenticated,
        error: 'Failed to refresh role - using cached data',
      );
    }
  }
}

/// Authentication data model
class AuthRoleData {
  final AuthRoleState authState;
  final AppUser? user;
  final String? error;

  const AuthRoleData({
    this.authState = AuthRoleState.initial,
    this.user,
    this.error,
  });

  AuthRoleData copyWith({
    AuthRoleState? authState,
    AppUser? user,
    String? error,
  }) {
    return AuthRoleData(
      authState: authState ?? this.authState,
      user: user ?? this.user,
      error: error,
    );
  }

  /// Check if user is fully authenticated with role resolved
  bool get isAuthenticated => authState == AuthRoleState.authenticated && user != null;
  
  /// Check if authentication is in progress
  bool get isLoading => authState == AuthRoleState.loading || authState == AuthRoleState.roleResolving;
  
  /// Check if there's an error
  bool get hasError => error != null;
  
  /// Get user role safely (defaults to waiter for security)
  UserRole get safeRole => user?.role ?? UserRole.waiter;
  
  /// Check if user has admin role
  bool get isAdmin => user?.role == UserRole.admin;
}

// Provider instances
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureAuthRoleProvider = StateNotifierProvider<SecureAuthRoleNotifier, AuthRoleData>((ref) {
  final authRepository = FirebaseAuthRepository();
  final secureStorage = ref.watch(secureStorageProvider);
  
  final notifier = SecureAuthRoleNotifier(authRepository, secureStorage);
  
  ref.onDispose(() {
    authRepository.dispose();
  });
  
  return notifier;
});

// Convenience providers
final currentUserProvider = Provider<AppUser?>((ref) {
  final authData = ref.watch(secureAuthRoleProvider);
  return authData.user;
});

final userRoleProvider = Provider<UserRole>((ref) {
  final authData = ref.watch(secureAuthRoleProvider);
  return authData.safeRole;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authData = ref.watch(secureAuthRoleProvider);
  return authData.isAuthenticated;
});

final isAdminProvider = Provider<bool>((ref) {
  final authData = ref.watch(secureAuthRoleProvider);
  return authData.isAdmin;
});

// Role-based permission providers
final canCreateOrdersProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canCreateOrders;
});

final canApproveOrdersProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canApproveOrders;
});

final canViewKitchenQueueProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canViewKitchenQueue;
});

final canViewBarQueueProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canViewBarQueue;
});

final canManageUsersProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canManageUsers;
});

final canManageProductsProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canManageProducts;
});

final canViewReportsProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canViewReports;
});

final canProcessPaymentsProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.canProcessPayments;
});