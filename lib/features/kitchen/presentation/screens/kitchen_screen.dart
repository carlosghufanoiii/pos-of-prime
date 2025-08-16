import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kitchen_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../features/auth/providers/appwrite_auth_provider.dart';
import '../widgets/kitchen_order_card.dart';
import '../widgets/delay_order_dialog.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen>
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
    final currentUser = ref.watch(appwriteCurrentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System'),
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
            Tab(text: 'New Orders', icon: Icon(Icons.fiber_new)),
            Tab(text: 'In Preparation', icon: Icon(Icons.restaurant)),
            Tab(text: 'Ready', icon: Icon(Icons.check_circle)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewOrdersTab(),
          _buildInPrepTab(),
          _buildReadyTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: _buildQuickActions(currentUser),
    );
  }

  Widget _buildNewOrdersTab() {
    final ordersAsync = ref.watch(kitchenOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kitchenOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          final newOrders = orders.where((order) => order.status == OrderStatus.approved).toList();
          
          if (newOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No new orders'),
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
              return KitchenOrderCard(
                order: order,
                onStartPrep: () => _startPreparation(order),
                onDelay: () => _showDelayDialog(order),
                showStartButton: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error, () => ref.refresh(kitchenOrdersProvider)),
      ),
    );
  }

  Widget _buildInPrepTab() {
    final ordersAsync = ref.watch(inPrepOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inPrepOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('No orders in preparation'),
                  Text('Orders will appear here when cooking starts'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return KitchenOrderCard(
                order: order,
                onMarkReady: () => _markOrderReady(order),
                onDelay: () => _showDelayDialog(order),
                showReadyButton: true,
                showPrepTime: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error, () => ref.refresh(inPrepOrdersProvider)),
      ),
    );
  }

  Widget _buildReadyTab() {
    final ordersAsync = ref.watch(readyOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(readyOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('No orders ready'),
                  Text('Completed orders await pickup'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return KitchenOrderCard(
                order: order,
                showWaitingTime: true,
                isCompleted: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error, () => ref.refresh(readyOrdersProvider)),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final statsAsync = ref.watch(kitchenStatsProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kitchenStatsProvider);
      },
      child: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kitchen Performance - ${DateTime.now().toString().split(' ')[0]}',
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
                      Icons.queue,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'In Preparation',
                      '${stats['inPrepOrders'] ?? 0}',
                      Icons.restaurant,
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
                      Icons.check_circle,
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
              
              // Performance Metrics
              Text(
                'Performance Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Average Prep Time:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(stats['averagePrepTime'] ?? 0.0).toStringAsFixed(1)} min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Orders Today:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${stats['totalOrdersToday'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Kitchen Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Start with orders that have been waiting longest'),
                    const Text('• Group similar dishes to optimize cooking time'),
                    const Text('• Mark orders ready as soon as they\'re finished'),
                    const Text('• Use delay function if prep time will exceed 30 minutes'),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error, () => ref.refresh(kitchenStatsProvider)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
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
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;

    final success = await ref.read(orderStatusProvider.notifier)
        .startPreparation(order.id, currentUser.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started preparation for Order ${order.orderNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAllData();
      } else {
        final error = ref.read(orderStatusProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start preparation: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markOrderReady(Order order) async {
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;

    final success = await ref.read(orderStatusProvider.notifier)
        .markOrderReady(order.id, currentUser.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} marked as ready'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAllData();
      } else {
        final error = ref.read(orderStatusProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark order ready: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDelayDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => DelayOrderDialog(order: order),
    );
  }

  void _refreshAllData() {
    ref.invalidate(kitchenOrdersProvider);
    ref.invalidate(inPrepOrdersProvider);
    ref.invalidate(readyOrdersProvider);
    ref.invalidate(kitchenStatsProvider);
  }
}