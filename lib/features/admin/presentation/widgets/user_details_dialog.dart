import 'package:flutter/material.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/user_role.dart';
import 'edit_user_dialog.dart';

class UserDetailsDialog extends StatelessWidget {
  final AppUser user;

  const UserDetailsDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.isActive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isActive ? Icons.check_circle : Icons.block,
                    size: 16,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // User Information
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Email', user.email, Icons.email),
            if (user.employeeId != null)
              _buildInfoRow('Employee ID', user.employeeId!, Icons.badge),
            if (user.phoneNumber != null)
              _buildInfoRow('Phone', user.phoneNumber!, Icons.phone),
            if (user.address != null)
              _buildInfoRow('Address', user.address!, Icons.location_on),

            const SizedBox(height: 20),

            // Account Information
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Created',
              _formatDateTime(user.createdAt),
              Icons.calendar_today,
            ),
            if (user.lastLoginAt != null)
              _buildInfoRow(
                'Last Login',
                _formatDateTime(user.lastLoginAt!),
                Icons.login,
              ),

            const SizedBox(height: 24),

            // Role Permissions
            const Text(
              'Role Permissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildPermissionChips(),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => EditUserDialog(user: user),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionChips() {
    final permissions = <String>[];
    
    if (user.role.canCreateOrders) permissions.add('Create Orders');
    if (user.role.canApproveOrders) permissions.add('Approve Orders');
    if (user.role.canViewKitchenQueue) permissions.add('Kitchen Queue');
    if (user.role.canViewBarQueue) permissions.add('Bar Queue');
    if (user.role.canManageUsers) permissions.add('User Management');
    if (user.role.canViewReports) permissions.add('Reports');

    return permissions.map((permission) {
      return Chip(
        label: Text(
          permission,
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
        side: BorderSide(color: _getRoleColor(user.role).withOpacity(0.3)),
      );
    }).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.adminColor;
      case UserRole.waiter:
        return AppTheme.waiterColor;
      case UserRole.cashier:
        return AppTheme.cashierColor;
      case UserRole.kitchen:
        return AppTheme.kitchenColor;
      case UserRole.bartender:
        return AppTheme.barColor;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}