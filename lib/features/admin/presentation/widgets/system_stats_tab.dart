import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../providers/admin_provider.dart';

class SystemStatsTab extends ConsumerWidget {
  const SystemStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemStatsAsync = ref.watch(systemStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(systemStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: systemStatsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(systemStatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health Overview
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'System Uptime',
                      '${stats['systemUptime']}',
                      Icons.trending_up,
                      Colors.green,
                      subtitle: 'Excellent',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Users',
                      '${stats['activeUsers']}',
                      Icons.people,
                      AppTheme.primaryColor,
                      subtitle: 'Currently online',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Response Time',
                      '${stats['averageResponseTime']}ms',
                      Icons.speed,
                      _getResponseTimeColor(stats['averageResponseTime']),
                      subtitle: _getResponseTimeStatus(stats['averageResponseTime']),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Error Rate',
                      '${(stats['errorRate'] as double).toStringAsFixed(2)}%',
                      Icons.error_outline,
                      _getErrorRateColor(stats['errorRate']),
                      subtitle: _getErrorRateStatus(stats['errorRate']),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Resource Usage
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resource Usage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResourceBar(
                        'CPU Usage',
                        stats['cpuUsage'],
                        '%',
                        Colors.blue,
                        Icons.memory,
                      ),
                      const SizedBox(height: 12),
                      _buildResourceBar(
                        'Memory Usage',
                        stats['memoryUsage'],
                        '%',
                        Colors.orange,
                        Icons.storage,
                      ),
                      const SizedBox(height: 12),
                      _buildResourceBar(
                        'Disk Usage',
                        stats['diskUsage'],
                        '%',
                        Colors.purple,
                        Icons.sd_storage,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Database Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Database Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              'Active Connections',
                              '${stats['dbConnections']}',
                              'of ${stats['maxDbConnections']} max',
                              Icons.link,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoTile(
                              'Total Transactions',
                              '${stats['totalTransactions']}',
                              'since startup',
                              Icons.swap_horiz,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        'Failed Transactions',
                        '${stats['failedTransactions']}',
                        'needs attention',
                        Icons.warning,
                        stats['failedTransactions'] > 0 ? Colors.red : Colors.green,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Maintenance Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maintenance Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMaintenanceItem(
                        'Last Backup',
                        _formatDateTime(stats['lastBackup']),
                        Icons.backup,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildMaintenanceItem(
                        'Next Maintenance',
                        _formatDateTime(stats['nextScheduledMaintenance']),
                        Icons.build,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton(
                            'Run Backup',
                            Icons.backup,
                            Colors.blue,
                            () => _showBackupDialog(context),
                          ),
                          _buildActionButton(
                            'Clear Cache',
                            Icons.clear_all,
                            Colors.orange,
                            () => _showClearCacheDialog(context),
                          ),
                          _buildActionButton(
                            'System Logs',
                            Icons.description,
                            Colors.green,
                            () => _showSystemLogsDialog(context),
                          ),
                          _buildActionButton(
                            'Performance Report',
                            Icons.assessment,
                            Colors.purple,
                            () => _showPerformanceReportDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBar(
    String title,
    dynamic value,
    String unit,
    Color color,
    IconData icon,
  ) {
    final percentage = value is double ? value : (value as int).toDouble();
    final displayValue = percentage.toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            Text(
              '$displayValue$unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getUsageColor(percentage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(_getUsageColor(percentage)),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );

    if (fullWidth) {
      return content;
    }

    return content;
  }

  Widget _buildMaintenanceItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
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

  Color _getResponseTimeColor(dynamic responseTime) {
    final time = responseTime is int ? responseTime : (responseTime as double).toInt();
    if (time < 200) return Colors.green;
    if (time < 500) return Colors.orange;
    return Colors.red;
  }

  String _getResponseTimeStatus(dynamic responseTime) {
    final time = responseTime is int ? responseTime : (responseTime as double).toInt();
    if (time < 200) return 'Excellent';
    if (time < 500) return 'Good';
    return 'Needs attention';
  }

  Color _getErrorRateColor(dynamic errorRate) {
    final rate = errorRate is double ? errorRate : (errorRate as int).toDouble();
    if (rate < 0.5) return Colors.green;
    if (rate < 2.0) return Colors.orange;
    return Colors.red;
  }

  String _getErrorRateStatus(dynamic errorRate) {
    final rate = errorRate is double ? errorRate : (errorRate as int).toDouble();
    if (rate < 0.5) return 'Excellent';
    if (rate < 2.0) return 'Acceptable';
    return 'High';
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 60) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Backup'),
        content: const Text('This will create a backup of the current database. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup started...')),
              );
            },
            child: const Text('Start Backup'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showSystemLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Logs'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              'System logs feature coming soon...\n\n'
              'This will show:\n'
              '• Application logs\n'
              '• Error logs\n'
              '• Access logs\n'
              '• Performance logs',
            ),
          ),
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

  void _showPerformanceReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Report'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              'Performance report feature coming soon...\n\n'
              'This will include:\n'
              '• Response time analysis\n'
              '• Resource usage trends\n'
              '• Error rate analysis\n'
              '• Database performance\n'
              '• Recommendations',
            ),
          ),
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
}