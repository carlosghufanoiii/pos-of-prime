import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bar_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../features/auth/providers/firebase_auth_provider.dart';
import '../widgets/bar_order_card.dart';
import '../widgets/bar_delay_dialog.dart';

class BarScreen extends ConsumerStatefulWidget {
  const BarScreen({super.key});

  @override
  ConsumerState<BarScreen> createState() => _BarScreenState();
}

class _BarScreenState extends ConsumerState<BarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(firebaseCurrentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bar Display System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'New Drinks', icon: Icon(Icons.local_bar)),
            Tab(text: 'In Preparation', icon: Icon(Icons.blender)),
            Tab(text: 'Ready', icon: Icon(Icons.done)),
            Tab(text: 'Bar Stats', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewDrinksTab(),
          _buildInPrepTab(),
          _buildReadyTab(),
          _buildBarStatsTab(),
        ],
      ),
      floatingActionButton: _buildQuickActions(currentUser),
    );
  }

  Widget _buildNewDrinksTab() {
    final ordersAsync = ref.watch(barOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(barOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          final newOrders = orders
              .where((order) => order.status == OrderStatus.approved)
              .toList();

          if (newOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('No new drink orders'),
                  Text('All orders are being prepared'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newOrders.length,
            itemBuilder: (context, index) {
              final order = newOrders[index];
              return BarOrderCard(
                order: order,
                onStartPrep: () => _startPreparation(order),
                onDelay: () => _showDelayDialog(order),
                showStartButton: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorView(error, () => ref.refresh(barOrdersProvider)),
      ),
    );
  }

  Widget _buildInPrepTab() {
    final ordersAsync = ref.watch(barInPrepOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(barInPrepOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.blender, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('No drinks in preparation'),
                  Text('Orders will appear here when mixing starts'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return BarOrderCard(
                order: order,
                onMarkReady: () => _markDrinkReady(order),
                onDelay: () => _showDelayDialog(order),
                showReadyButton: true,
                showPrepTime: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorView(error, () => ref.refresh(barInPrepOrdersProvider)),
      ),
    );
  }

  Widget _buildReadyTab() {
    final ordersAsync = ref.watch(barReadyOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(barReadyOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_drink, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('No drinks ready'),
                  Text('Completed drinks await pickup'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return BarOrderCard(
                order: order,
                showWaitingTime: true,
                isCompleted: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorView(error, () => ref.refresh(barReadyOrdersProvider)),
      ),
    );
  }

  Widget _buildBarStatsTab() {
    final statsAsync = ref.watch(barStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(barStatsProvider);
      },
      child: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bar Performance - ${DateTime.now().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Current Queue Status
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Orders',
                      '${stats['pendingOrders'] ?? 0}',
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'In Preparation',
                      '${stats['inPrepOrders'] ?? 0}',
                      Icons.blender,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Ready for Pickup',
                      '${stats['readyOrders'] ?? 0}',
                      Icons.done,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Completed Today',
                      '${stats['completedToday'] ?? 0}',
                      Icons.done_all,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Drink Statistics
              Text(
                'Drink Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDrinkStatCard(
                      'Alcoholic Drinks',
                      '${stats['alcoholicDrinks'] ?? 0}',
                      Icons.wine_bar,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDrinkStatCard(
                      'Non-Alcoholic',
                      '${stats['nonAlcoholicDrinks'] ?? 0}',
                      Icons.local_drink,
                      Colors.cyan,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[100]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_bar,
                          color: Colors.purple[700],
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Drinks Today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats['totalDrinks'] ?? 0}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Performance Metrics - Enhanced UI
              Text(
                'Performance Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Performance Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'Avg Prep Time',
                      '${(stats['averagePrepTime'] ?? 0.0).toStringAsFixed(1)} min',
                      Icons.timer,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPerformanceCard(
                      'Orders Today',
                      '${stats['totalOrdersToday'] ?? 0}',
                      Icons.receipt,
                      Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Additional Performance Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'Peak Hour',
                      '${stats['peakHour'] ?? 'N/A'}',
                      Icons.trending_up,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPerformanceCard(
                      'Efficiency Rate',
                      '${(stats['efficiencyRate'] ?? 0.0).toStringAsFixed(0)}%',
                      Icons.speed,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bar Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyan[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.cyan[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Bar Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Check alcohol ID for all alcoholic beverages',
                    ),
                    const Text(
                      '• Prepare non-alcoholic drinks first for efficiency',
                    ),
                    const Text('• Keep ice levels stocked during peak hours'),
                    const Text(
                      '• Serve cocktails immediately after preparation',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorView(error, () => ref.refresh(barStatsProvider)),
      ),
    );
  }

  Widget _buildStatCard(
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
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkStatCard(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildErrorView(Object error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget? _buildQuickActions(user) {
    if (user == null) return null;

    return FloatingActionButton(
      onPressed: () => _refreshAllData(),
      child: const Icon(Icons.refresh),
    );
  }

  Future<void> _startPreparation(Order order) async {
    final currentUser = ref.read(firebaseCurrentUserProvider);
    if (currentUser == null) return;

    final success = await ref
        .read(barOrderStatusProvider.notifier)
        .startPreparation(order.id, currentUser.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Started preparing drinks for Order ${order.orderNumber}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAllData();
      } else {
        final error = ref.read(barOrderStatusProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start preparation: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markDrinkReady(Order order) async {
    final currentUser = ref.read(firebaseCurrentUserProvider);
    if (currentUser == null) return;

    final success = await ref
        .read(barOrderStatusProvider.notifier)
        .markDrinkReady(order.id, currentUser.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Drinks ready for Order ${order.orderNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAllData();
      } else {
        final error = ref.read(barOrderStatusProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark drinks ready: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDelayDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => BarDelayDialog(order: order),
    );
  }

  void _refreshAllData() {
    ref.refresh(barOrdersProvider);
    ref.refresh(barInPrepOrdersProvider);
    ref.refresh(barReadyOrdersProvider);
    ref.refresh(barStatsProvider);
  }
}
