import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/user_role.dart';
import '../../../auth/providers/appwrite_auth_provider.dart';
import '../../../waiter/presentation/screens/waiter_order_screen.dart';
import '../../../cashier/presentation/screens/cashier_screen.dart';
import '../../../kitchen/presentation/screens/kitchen_screen.dart';
import '../../../bar/presentation/screens/bar_screen.dart';
import '../../../admin/presentation/screens/admin_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final AppUser user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.role.displayName} Dashboard'),
        backgroundColor: _getRoleColor(user.role),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getRoleColor(user.role),
                      child: Text(
                        user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.displayName}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Role: ${user.role.displayName}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.lastLoginAt != null)
                            Text(
                              'Last login: ${_formatDateTime(user.lastLoginAt!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: _buildQuickActions(context, user.role),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickActions(BuildContext context, UserRole role) {
    List<Widget> actions = [];

    if (role.canCreateOrders) {
      actions.add(_buildActionCard(
        'Create Order',
        Icons.add_shopping_cart,
        AppTheme.waiterColor,
        () => _navigateToFeature(context, 'waiter'),
      ));
    }

    if (role.canApproveOrders) {
      actions.add(_buildActionCard(
        'Cashier',
        Icons.point_of_sale,
        AppTheme.cashierColor,
        () => _navigateToFeature(context, 'cashier'),
      ));
    }

    if (role.canViewKitchenQueue) {
      actions.add(_buildActionCard(
        'Kitchen Display',
        Icons.restaurant,
        AppTheme.kitchenColor,
        () => _navigateToFeature(context, 'kitchen'),
      ));
    }

    if (role.canViewBarQueue) {
      actions.add(_buildActionCard(
        'Bar Display',
        Icons.local_bar,
        AppTheme.barColor,
        () => _navigateToFeature(context, 'bar'),
      ));
    }

    if (role.canManageUsers) {
      actions.add(_buildActionCard(
        'Admin Panel',
        Icons.admin_panel_settings,
        AppTheme.adminColor,
        () => _navigateToFeature(context, 'admin'),
      ));
    }

    if (role.canViewReports) {
      actions.add(_buildActionCard(
        'Reports',
        Icons.bar_chart,
        AppTheme.primaryColor,
        () => _navigateToFeature(context, 'reports'),
      ));
    }

    return actions;
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.waiter:
        return AppTheme.waiterColor;
      case UserRole.cashier:
        return AppTheme.cashierColor;
      case UserRole.kitchen:
        return AppTheme.kitchenColor;
      case UserRole.bartender:
        return AppTheme.barColor;
      case UserRole.admin:
        return AppTheme.adminColor;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToFeature(BuildContext context, String feature) {
    switch (feature) {
      case 'waiter':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WaiterOrderScreen(),
          ),
        );
        break;
      case 'cashier':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CashierScreen(),
          ),
        );
        break;
      case 'kitchen':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const KitchenScreen(),
          ),
        );
        break;
      case 'bar':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BarScreen(),
          ),
        );
        break;
      case 'admin':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdminScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$feature module coming soon!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // AuthWrapper will automatically handle navigation back to login
                await ref.read(appwriteAuthControllerProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}