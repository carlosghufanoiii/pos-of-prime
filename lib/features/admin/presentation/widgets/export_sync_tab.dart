import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/providers/export_sync_provider.dart';
import '../../../../shared/services/offline_sync_service.dart';
import '../../providers/admin_provider.dart';

class ExportSyncTab extends ConsumerWidget {
  const ExportSyncTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportProvider);
    final syncStatus = ref.watch(offlineSyncStatusProvider);
    final connectivityStatus = ref.watch(connectivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(offlineOrdersProvider);
        ref.invalidate(offlineUsersProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            _buildConnectionStatus(connectivityStatus),

            const SizedBox(height: 24),

            // Offline Sync Status
            _buildSyncStatus(context, ref, syncStatus),

            const SizedBox(height: 24),

            // Export Section
            _buildExportSection(context, ref, exportState),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context, ref),

            const SizedBox(height: 24),

            // Offline Data Overview
            _buildOfflineDataOverview(context, ref, syncStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(AsyncValue<List<ConnectivityResult>> connectivityStatus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              connectivityStatus.when(
                data: (connectivity) => connectivity.contains(ConnectivityResult.none)
                    ? Icons.wifi_off
                    : Icons.wifi,
                loading: () => Icons.wifi_find,
                error: (_, __) => Icons.error,
              ),
              color: connectivityStatus.when(
                data: (connectivity) => connectivity.contains(ConnectivityResult.none)
                    ? Colors.red
                    : Colors.green,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    connectivityStatus.when(
                      data: (connectivity) =>
                          connectivity.contains(ConnectivityResult.none)
                          ? 'Offline - Working with local data'
                          : 'Online - Ready to sync',
                      loading: () => 'Checking connection...',
                      error: (_, __) => 'Connection check failed',
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    WidgetRef ref,
    OfflineSyncStatus syncStatus,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offline Sync Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (syncStatus.isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(offlineSyncStatusProvider.notifier).startSync();
                    },
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            if (syncStatus.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncStatus.error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(offlineSyncStatusProvider.notifier)
                            .clearError();
                      },
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.red[700],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Sync Statistics
            if (syncStatus.isInitialized) ...[
              const Text(
                'Unsynced Items',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSyncStatCard(
                      'Orders',
                      syncStatus.unsyncedCounts['unsyncedOrders'] ?? 0,
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSyncStatCard(
                      'Users',
                      syncStatus.unsyncedCounts['unsyncedUsers'] ?? 0,
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (syncStatus.lastSyncAt != null)
                Text(
                  'Last sync: ${_formatDateTime(syncStatus.lastSyncAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    WidgetRef ref,
    ExportState exportState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Export',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (exportState.isExporting) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Exporting data...'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (exportState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exportState.error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (exportState.successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exportState.successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                    if (exportState.exportedFilePath != null) ...[
                      IconButton(
                        onPressed: () {
                          ref
                              .read(exportProvider.notifier)
                              .shareFile(
                                exportState.exportedFilePath!,
                                exportState.exportedFilePath!.split('/').last,
                              );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        tooltip: 'Share file',
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(exportProvider.notifier)
                              .openFile(exportState.exportedFilePath!);
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        tooltip: 'Open file',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export Options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildExportButton(
                  'Export Orders (CSV)',
                  Icons.file_download,
                  Colors.blue,
                  () => _exportOrders(ref, 'csv'),
                  enabled: !exportState.isExporting,
                ),
                _buildExportButton(
                  'Export Orders (Excel)',
                  Icons.table_chart,
                  Colors.green,
                  () => _exportOrders(ref, 'excel'),
                  enabled: !exportState.isExporting,
                ),
                _buildExportButton(
                  'Export Users (CSV)',
                  Icons.people,
                  Colors.purple,
                  () => _exportUsers(ref),
                  enabled: !exportState.isExporting,
                ),
                _buildExportButton(
                  'Create Backup',
                  Icons.backup,
                  Colors.orange,
                  () => _createBackup(ref),
                  enabled: !exportState.isExporting,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'View Offline Orders',
                  Icons.storage,
                  Colors.blue,
                  () => _showOfflineOrdersDialog(context, ref),
                ),
                _buildActionButton(
                  'Clear Offline Data',
                  Icons.clear_all,
                  Colors.red,
                  () => _showClearDataDialog(context, ref),
                ),
                _buildActionButton(
                  'Sales Report',
                  Icons.assessment,
                  Colors.green,
                  () => _showSalesReportDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildOfflineDataOverview(
    BuildContext context,
    WidgetRef ref,
    OfflineSyncStatus syncStatus,
  ) {
    if (!syncStatus.isInitialized) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline Data Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataOverviewCard(
                    'Total Orders Offline',
                    '${syncStatus.unsyncedCounts['unsyncedOrders'] ?? 0}',
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataOverviewCard(
                    'Pending Sync Items',
                    '${syncStatus.unsyncedCounts['pendingSyncItems'] ?? 0}',
                    Icons.sync_problem,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _exportOrders(WidgetRef ref, String format) async {
    final offlineOrders = await ref.read(offlineOrdersProvider.future);

    if (format == 'csv') {
      await ref.read(exportProvider.notifier).exportOrdersToCSV(offlineOrders);
    } else if (format == 'excel') {
      await ref
          .read(exportProvider.notifier)
          .exportOrdersToExcel(offlineOrders);
    }
  }

  Future<void> _exportUsers(WidgetRef ref) async {
    final users = await ref.read(allUsersProvider.future);
    await ref.read(exportProvider.notifier).exportUsersToCSV(users);
  }

  Future<void> _createBackup(WidgetRef ref) async {
    final orders = await ref.read(offlineOrdersProvider.future);
    final users = await ref.read(allUsersProvider.future);
    await ref.read(exportProvider.notifier).generateBackupFile(orders, users);
  }

  void _showOfflineOrdersDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Orders'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: Text('Feature to view offline orders coming soon...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text(
          'This will permanently delete all offline data. '
          'Make sure you have synced all important data first. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OfflineSyncService.clearOfflineData();
                ref.invalidate(offlineSyncStatusProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline data cleared successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear data: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showSalesReportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales Report'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: Text('Detailed sales report feature coming soon...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
