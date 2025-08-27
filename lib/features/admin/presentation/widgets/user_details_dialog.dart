import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/user_role.dart';
import '../../providers/admin_provider.dart';
import 'edit_user_dialog.dart';

class UserDetailsDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const UserDetailsDialog({super.key, required this.user});

  @override
  ConsumerState<UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends ConsumerState<UserDetailsDialog> {
  bool _isLoading = false;

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
                  backgroundColor: _getRoleColor(widget.user.role),
                  child: Text(
                    widget.user.name.substring(0, 1).toUpperCase(),
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
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(widget.user.role).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.user.role.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getRoleColor(widget.user.role),
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
                color: widget.user.isActive
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.user.isActive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.user.isActive ? Icons.check_circle : Icons.block,
                    size: 16,
                    color: widget.user.isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: widget.user.isActive ? Colors.green : Colors.red,
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Email', widget.user.email, Icons.email),
            if (widget.user.employeeId != null)
              _buildInfoRow('Employee ID', widget.user.employeeId!, Icons.badge),
            if (widget.user.phoneNumber != null)
              _buildInfoRow('Phone', widget.user.phoneNumber!, Icons.phone),
            if (widget.user.address != null)
              _buildInfoRow('Address', widget.user.address!, Icons.location_on),

            const SizedBox(height: 20),

            // Account Information
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Created',
              _formatDateTime(widget.user.createdAt),
              Icons.calendar_today,
            ),
            if (widget.user.lastLoginAt != null)
              _buildInfoRow(
                'Last Login',
                _formatDateTime(widget.user.lastLoginAt!),
                Icons.login,
              ),

            const SizedBox(height: 24),

            // Role Permissions
            const Text(
              'Role Permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(spacing: 8, runSpacing: 8, children: _buildPermissionChips()),

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
                  onPressed: _isLoading ? null : _toggleUserStatus,
                  icon: Icon(widget.user.isActive ? Icons.block : Icons.check_circle),
                  label: Text(widget.user.isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.user.isActive ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _editUser,
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

  Future<void> _editUser() async {
    Navigator.of(context).pop();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: widget.user),
    );
    
    // If user was updated, you might want to refresh the parent widget
    if (result == true && mounted) {
      // The parent widget should handle refreshing the user list
      Navigator.of(context).pop(true); // Return true to indicate changes were made
    }
  }

  Future<void> _toggleUserStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(userManagementProvider.notifier)
          .toggleUserStatus(widget.user.id, !widget.user.isActive);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${widget.user.name} ${!widget.user.isActive ? "activated" : "deactivated"}',
              ),
              backgroundColor: !widget.user.isActive ? Colors.green : Colors.orange,
            ),
          );
          
          // Close dialog and refresh parent
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update user status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (widget.user.role.canCreateOrders) permissions.add('Create Orders');
    if (widget.user.role.canApproveOrders) permissions.add('Approve Orders');
    if (widget.user.role.canViewKitchenQueue) permissions.add('Kitchen Queue');
    if (widget.user.role.canViewBarQueue) permissions.add('Bar Queue');
    if (widget.user.role.canManageUsers) permissions.add('User Management');
    if (widget.user.role.canViewReports) permissions.add('Reports');

    return permissions.map((permission) {
      return Chip(
        label: Text(permission, style: const TextStyle(fontSize: 12)),
        backgroundColor: _getRoleColor(widget.user.role).withValues(alpha: 0.1),
        side: BorderSide(color: _getRoleColor(widget.user.role).withValues(alpha: 0.3)),
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
