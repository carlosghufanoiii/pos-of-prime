import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/constants/app_theme.dart';
import '../shared/constants/app_constants.dart';
import '../shared/models/user_role.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/providers/secure_auth_role_provider.dart';
import '../features/admin/presentation/screens/admin_screen.dart';
import '../shared/services/role_navigation_service.dart';
import '../shared/utils/logger.dart';

class PrimePOSApp extends ConsumerWidget {
  const PrimePOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '${AppConstants.appName} - ${AppConstants.brandTagline}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Nightclub theme is always dark
      home: const SecureAuthWrapper(),
    );
  }
}

class SecureAuthWrapper extends ConsumerStatefulWidget {
  const SecureAuthWrapper({super.key});

  @override
  ConsumerState<SecureAuthWrapper> createState() => _SecureAuthWrapperState();
}

class _SecureAuthWrapperState extends ConsumerState<SecureAuthWrapper> {
  @override
  void initState() {
    super.initState();
    // FAST STARTUP: Initialize data services in background after UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Initialize data service in background (non-blocking)
        _initializeDataServicesInBackground();
      }
    });
  }

  void _initializeDataServicesInBackground() {
    Future(() async {
      try {
        final dataService = ref.read(dataServiceProvider);
        await dataService.initialize().timeout(
          const Duration(seconds: 3), // Reduced timeout
          onTimeout: () {
            Logger.warning('⚡ Data service init timeout, continuing', tag: 'AuthWrapper');
          },
        );
        Logger.info('⚡ Data services initialized in background', tag: 'AuthWrapper');
      } catch (e) {
        Logger.warning('⚡ Background data service init failed: $e', tag: 'AuthWrapper');
        // Continue - app works without these services
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authData = ref.watch(secureAuthRoleProvider);

    // Add listener for automatic navigation after role resolution
    ref.listen<AuthRoleData>(secureAuthRoleProvider, (previous, next) {
      _handleAuthStateChange(context, previous, next);
    });

    // Return appropriate screen based on authentication state
    switch (authData.authState) {
      case AuthRoleState.initial:
      case AuthRoleState.loading:
      case AuthRoleState.roleResolving:
        return const SplashScreen();

      case AuthRoleState.unauthenticated:
        return const LoginScreen();

      case AuthRoleState.error:
        // Show login screen for errors, but allow retry
        return const LoginScreen();

      case AuthRoleState.authenticated:
        return _buildAuthenticatedScreen(authData);
    }
  }

  /// Handle authentication state changes with proper navigation
  void _handleAuthStateChange(
    BuildContext context,
    AuthRoleData? previous,
    AuthRoleData next,
  ) {
    // Only handle navigation when context is still mounted
    if (!mounted) return;

    // Handle successful authentication
    if (previous?.authState != AuthRoleState.authenticated && 
        next.authState == AuthRoleState.authenticated &&
        next.user != null) {
      
      final user = next.user!;
      Logger.info(
        '✅ Authentication complete: ${user.email} (${user.role.displayName})', 
        tag: 'AuthWrapper'
      );
      
      // No need to navigate manually - the build method will handle the UI update
    }

    // Handle authentication errors
    if (next.hasError && previous?.error != next.error) {
      Logger.error('Authentication error: ${next.error}', tag: 'AuthWrapper');
      
      // Show error message if needed
      if (next.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  /// Build the appropriate screen for authenticated users
  Widget _buildAuthenticatedScreen(AuthRoleData authData) {
    final user = authData.user!;
    
    Logger.info(
      '🏠 Building home screen for ${user.role.displayName}', 
      tag: 'AuthWrapper'
    );

    // Route based on user role - single navigation, no race conditions
    if (user.role == UserRole.admin) {
      // Admin users go to admin dashboard
      return const AdminScreen();
    } else {
      // All other users go to their role-specific screens
      return RoleNavigationService.getPrimaryScreenForRole(user.role);
    }
  }
}

// Provider for data service initialization
final dataServiceProvider = Provider((ref) {
  // This would be your DataService.instance
  // For now, return a mock implementation
  return MockDataService();
});

// Mock data service for initialization
class MockDataService {
  Future<void> initialize() async {
    // Mock initialization
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
