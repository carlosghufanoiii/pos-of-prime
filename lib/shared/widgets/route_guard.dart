import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';
import '../../features/auth/providers/secure_auth_role_provider.dart';

/// Widget that guards access to routes based on user permissions
class RouteGuard extends ConsumerWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final Widget? fallbackWidget;
  final String? routeName;

  const RouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.fallbackWidget,
    this.routeName,
  });

  /// Admin-only route guard
  const RouteGuard.adminOnly({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.routeName,
  }) : allowedRoles = const [UserRole.admin];

  /// Multi-role route guard for cashier/waiter/bartender
  const RouteGuard.operationalRoles({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.routeName,
  }) : allowedRoles = const [
          UserRole.waiter,
          UserRole.cashier,
          UserRole.bartender,
        ];

  /// Kitchen-only route guard
  const RouteGuard.kitchenOnly({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.routeName,
  }) : allowedRoles = const [UserRole.kitchen];

  /// Bar-only route guard
  const RouteGuard.barOnly({
    super.key,
    required this.child,
    this.fallbackWidget,
    this.routeName,
  }) : allowedRoles = const [UserRole.bartender];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(secureAuthRoleProvider);

    // Handle authentication states
    switch (authData.authState) {
      case AuthRoleState.initial:
      case AuthRoleState.loading:
      case AuthRoleState.roleResolving:
        return _buildLoadingWidget();

      case AuthRoleState.unauthenticated:
      case AuthRoleState.error:
        Logger.warning(
          '🚫 Access denied to ${routeName ?? "route"}: User not authenticated', 
          tag: 'RouteGuard'
        );
        return _buildUnauthorizedWidget(context, 'Please login to continue');

      case AuthRoleState.authenticated:
        return _buildAuthenticatedContent(context, ref, authData);
    }
  }

  Widget _buildAuthenticatedContent(BuildContext context, WidgetRef ref, AuthRoleData authData) {
    final userRole = authData.user!.role;

    // Check if user's role is in allowed roles
    if (allowedRoles.contains(userRole)) {
      Logger.debug(
        '✅ Access granted to ${routeName ?? "route"}: ${userRole.displayName}', 
        tag: 'RouteGuard'
      );
      return child;
    } else {
      Logger.warning(
        '🚫 Access denied to ${routeName ?? "route"}: ${userRole.displayName} not in ${allowedRoles.map((r) => r.displayName).join(", ")}', 
        tag: 'RouteGuard'
      );
      return _buildUnauthorizedWidget(
        context, 
        'Access denied: Insufficient permissions for ${routeName ?? "this page"}'
      );
    }
  }

  Widget _buildLoadingWidget() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Verifying permissions...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthorizedWidget(BuildContext context, String message) {
    return fallbackWidget ?? Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // Navigate to appropriate home screen based on role
                    _navigateToAppropriateHome(context);
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAppropriateHome(BuildContext context) {
    // This would typically navigate to the main dashboard or role-specific home
    // For now, we'll just pop to root
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

/// Mixin for widgets that need role-based access control
mixin RoleBasedAccessMixin {
  /// Check if user has any of the specified roles
  bool hasAnyRole(WidgetRef ref, List<UserRole> roles) {
    final authData = ref.read(secureAuthRoleProvider);
    if (!authData.isAuthenticated) return false;
    return roles.contains(authData.user!.role);
  }

  /// Check if user has specific role
  bool hasRole(WidgetRef ref, UserRole role) {
    final authData = ref.read(secureAuthRoleProvider);
    if (!authData.isAuthenticated) return false;
    return authData.user!.role == role;
  }

  /// Check if user is admin
  bool isAdmin(WidgetRef ref) {
    return hasRole(ref, UserRole.admin);
  }

  /// Get current user role safely
  UserRole getCurrentRole(WidgetRef ref) {
    final authData = ref.read(secureAuthRoleProvider);
    return authData.safeRole;
  }

  /// Show access denied message
  void showAccessDeniedMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access denied: You cannot access $feature'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Wrapper for conditional role-based rendering
class RoleBasedWidget extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(secureAuthRoleProvider);

    if (!authData.isAuthenticated) {
      return fallback ?? const SizedBox.shrink();
    }

    if (allowedRoles.contains(authData.user!.role)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}