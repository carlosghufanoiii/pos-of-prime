import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../widgets/role_screen_wrapper.dart';
import '../widgets/fallback_screen.dart';
import '../../features/waiter/presentation/screens/waiter_order_screen.dart';
import '../../features/cashier/presentation/screens/cashier_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_screen.dart';
import '../../features/bar/presentation/screens/bar_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';

/// Service to handle role-based navigation and access control
class RoleNavigationService {
  /// Get the primary screen for a user role
  static Widget getPrimaryScreenForRole(UserRole role) {
    try {
      switch (role) {
        case UserRole.admin:
          return const AdminScreen();
        case UserRole.waiter:
          return const RoleScreenWrapper(
            title: 'Order System',
            child: WaiterOrderScreen(),
          );
        case UserRole.cashier:
          return const RoleScreenWrapper(
            title: 'Cashier System',
            child: CashierScreen(),
          );
        case UserRole.kitchen:
          return const RoleScreenWrapper(
            title: 'Kitchen Display',
            child: KitchenScreen(),
          );
        case UserRole.bartender:
          return const RoleScreenWrapper(
            title: 'Bar Display',
            child: BarScreen(),
          );
      }
    } catch (e) {
      // Fallback screen if primary screen fails to load
      return _buildFallbackScreen(role, e);
    }
  }

  /// Build fallback screen when primary screen fails
  static Widget _buildFallbackScreen(UserRole role, dynamic error) {
    return FallbackScreen(
      title: '${role.displayName} - Loading Issue',
      message: 'The ${role.displayName} service is starting up. This may take a moment...',
      icon: Icons.hourglass_empty,
      onRetry: () {
        // Could trigger app restart or refresh in the future
      },
    );
  }

  /// Check if a user role can access a specific feature
  static bool canAccessFeature(UserRole role, String feature) {
    switch (feature) {
      case 'waiter':
        return role.canCreateOrders;
      case 'cashier':
        return role.canApproveOrders || role.canProcessPayments;
      case 'kitchen':
        return role.canViewKitchenQueue;
      case 'bar':
        return role.canViewBarQueue;
      case 'admin':
        return role.canManageUsers || role.canManageProducts;
      case 'reports':
        return role.canViewReports;
      default:
        return false;
    }
  }

  /// Get available navigation options for a user role
  static List<NavigationOption> getNavigationOptionsForRole(UserRole role) {
    List<NavigationOption> options = [];

    // Admin users get access to everything
    if (role == UserRole.admin) {
      options.addAll([
        NavigationOption(
          'admin',
          'Admin Panel',
          Icons.admin_panel_settings,
          const Color(0xFFFF6B6B),
        ),
        NavigationOption(
          'waiter',
          'Create Order',
          Icons.add_shopping_cart,
          const Color(0xFF4ECDC4),
        ),
        NavigationOption(
          'cashier',
          'Cashier',
          Icons.point_of_sale,
          const Color(0xFF45B7D1),
        ),
        NavigationOption(
          'kitchen',
          'Kitchen Display',
          Icons.restaurant,
          const Color(0xFF96CEB4),
        ),
        NavigationOption(
          'bar',
          'Bar Display',
          Icons.local_bar,
          const Color(0xFFFECA57),
        ),
        NavigationOption(
          'reports',
          'Reports',
          Icons.bar_chart,
          const Color(0xFF6C5CE7),
        ),
      ]);
      return options;
    }

    // Role-specific access only
    if (role.canCreateOrders) {
      options.add(
        NavigationOption(
          'waiter',
          'Create Order',
          Icons.add_shopping_cart,
          const Color(0xFF4ECDC4),
        ),
      );
    }

    if (role.canApproveOrders || role.canProcessPayments) {
      options.add(
        NavigationOption(
          'cashier',
          'Cashier',
          Icons.point_of_sale,
          const Color(0xFF45B7D1),
        ),
      );
    }

    if (role.canViewKitchenQueue) {
      options.add(
        NavigationOption(
          'kitchen',
          'Kitchen Display',
          Icons.restaurant,
          const Color(0xFF96CEB4),
        ),
      );
    }

    if (role.canViewBarQueue) {
      options.add(
        NavigationOption(
          'bar',
          'Bar Display',
          Icons.local_bar,
          const Color(0xFFFECA57),
        ),
      );
    }

    if (role.canViewReports) {
      options.add(
        NavigationOption(
          'reports',
          'Reports',
          Icons.bar_chart,
          const Color(0xFF6C5CE7),
        ),
      );
    }

    return options;
  }

  /// Navigate to a specific feature (with permission check)
  static void navigateToFeature(
    BuildContext context,
    String feature,
    UserRole userRole,
  ) {
    if (!canAccessFeature(userRole, feature)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access denied: Insufficient permissions for $feature'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Widget screen;
    switch (feature) {
      case 'waiter':
        screen = const RoleScreenWrapper(
          title: 'Order System',
          showBackButton: true,
          child: WaiterOrderScreen(),
        );
        break;
      case 'cashier':
        screen = const RoleScreenWrapper(
          title: 'Cashier System',
          showBackButton: true,
          child: CashierScreen(),
        );
        break;
      case 'kitchen':
        screen = const RoleScreenWrapper(
          title: 'Kitchen Display',
          showBackButton: true,
          child: KitchenScreen(),
        );
        break;
      case 'bar':
        screen = const RoleScreenWrapper(
          title: 'Bar Display',
          showBackButton: true,
          child: BarScreen(),
        );
        break;
      case 'admin':
        screen = const AdminScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$feature module coming soon!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  /// Get the home screen route based on user role
  static String getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.waiter:
        return '/waiter';
      case UserRole.cashier:
        return '/cashier';
      case UserRole.kitchen:
        return '/kitchen';
      case UserRole.bartender:
        return '/bar';
    }
  }

  /// Check if user should see the dashboard or go directly to their role screen
  static bool shouldShowDashboard(UserRole role) {
    // Only admins see the dashboard with multiple options
    // All other roles go directly to their assigned screen
    return role == UserRole.admin;
  }
}

/// Navigation option model
class NavigationOption {
  final String route;
  final String title;
  final IconData icon;
  final Color color;

  NavigationOption(this.route, this.title, this.icon, this.color);
}
