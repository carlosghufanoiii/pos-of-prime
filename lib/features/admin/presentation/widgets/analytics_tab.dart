import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../providers/admin_provider.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAnalyticsAsync = ref.watch(salesAnalyticsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesAnalyticsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: salesAnalyticsAsync.when(
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
                  onPressed: () => ref.invalidate(salesAnalyticsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (analytics) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSalesCard(
                      'Today\'s Sales',
                      '₱${(analytics['todaySales'] as double).toStringAsFixed(2)}',
                      Icons.today,
                      Colors.green,
                      subtitle: 'vs yesterday: ${_getGrowthText(analytics)}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Total Orders',
                      '${analytics['totalOrders']}',
                      Icons.receipt_long,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSalesCard(
                      'Average Order',
                      '₱${(analytics['averageOrderValue'] as double).toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSalesCard(
                      'Sales Growth',
                      '${(analytics['salesGrowth'] as double).toStringAsFixed(1)}%',
                      Icons.show_chart,
                      (analytics['salesGrowth'] as double) > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Weekly and Monthly Sales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'This Week',
                              '₱${(analytics['weekSales'] as double).toStringAsFixed(2)}',
                              Icons.calendar_view_week,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'This Month',
                              '₱${(analytics['monthSales'] as double).toStringAsFixed(2)}',
                              Icons.calendar_month,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Performance Insights
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInsightRow(
                        'Top Selling Category',
                        analytics['topSellingCategory'],
                        Icons.category,
                      ),
                      _buildInsightRow(
                        'Peak Hours',
                        analytics['peakHour'],
                        Icons.access_time,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Methods
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethods(analytics['paymentMethods']),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Hourly Sales Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hourly Sales Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildHourlySalesChart(analytics['hourlySales']),
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

  Widget _buildSalesCard(
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

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(Map<String, dynamic> paymentMethods) {
    final methods = [
      {'name': 'Cash', 'percentage': paymentMethods['cash'], 'color': Colors.green},
      {'name': 'Card', 'percentage': paymentMethods['card'], 'color': Colors.blue},
      {'name': 'E-Wallet', 'percentage': paymentMethods['eWallet'], 'color': Colors.purple},
    ];

    return Column(
      children: methods.map((method) {
        final percentage = method['percentage'] as double;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: method['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(method['name'] as String),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(method['color'] as Color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHourlySalesChart(List<dynamic> hourlySales) {
    final maxSales = hourlySales
        .map((e) => e['sales'] as double)
        .reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: hourlySales.length,
      itemBuilder: (context, index) {
        final sale = hourlySales[index];
        final hour = sale['hour'] as String;
        final amount = sale['sales'] as double;
        final height = (amount / maxSales) * 150;

        return Container(
          width: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '₱${(amount / 1000).toStringAsFixed(1)}K',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hour,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGrowthText(Map<String, dynamic> analytics) {
    final todaySales = analytics['todaySales'] as double;
    final yesterdaySales = analytics['yesterdaySales'] as double;
    final growth = ((todaySales - yesterdaySales) / yesterdaySales * 100);
    
    if (growth > 0) {
      return '+${growth.toStringAsFixed(1)}%';
    } else {
      return '${growth.toStringAsFixed(1)}%';
    }
  }
}