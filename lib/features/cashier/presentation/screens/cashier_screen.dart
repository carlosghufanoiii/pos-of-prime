import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cashier_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/services/order_service.dart';
import '../../../../shared/providers/realtime_order_provider.dart';
import '../../../../features/auth/providers/appwrite_auth_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/order_details_sheet.dart';
import '../widgets/void_order_dialog.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Cashier Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approval', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Ready for Payment', icon: Icon(Icons.payment)),
            Tab(text: 'Daily Summary', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingOrdersTab(),
          _buildApprovedOrdersTab(),
          _buildDailySummaryTab(),
        ],
      ),
      floatingActionButton: _buildQuickActions(currentUser),
    );
  }

  Widget _buildPendingOrdersTab() {
    final ordersAsync = ref.watch(pendingOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh the realtime orders provider
        ref.invalidate(realtimeOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending orders'),
                  Text('All orders have been processed'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () => _showOrderDetails(order),
                onApprove: () => _approveOrder(order),
                onVoid: () => _showVoidDialog(order),
                showApproveButton: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(pendingOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedOrdersTab() {
    final ordersAsync = ref.watch(approvedOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh the realtime orders provider
        ref.invalidate(realtimeOrdersProvider);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('No orders ready for payment'),
                  Text('Approved orders will appear here'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () => _showOrderDetails(order),
                onPayment: () => _showPaymentDialog(order),
                showPaymentButton: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(approvedOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySummaryTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: OrderService.getDailySummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final summary = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Summary - ${DateTime.now().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Order Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Orders',
                      '${summary['totalOrders']}',
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Paid Orders',
                      '${summary['paidOrders']}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Pending Orders',
                      '${summary['pendingOrders']}',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Sales',
                      CurrencyFormatter.format(summary['totalSales']),
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Payment Method Breakdown
              Text(
                'Payment Methods',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildPaymentMethodCard(
                'Cash',
                CurrencyFormatter.format(summary['cashSales']),
                Icons.money,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodCard(
                'Card',
                CurrencyFormatter.format(summary['cardSales']),
                Icons.credit_card,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodCard(
                'E-Wallet',
                CurrencyFormatter.format(summary['eWalletSales']),
                Icons.smartphone,
                Colors.purple,
              ),
              
              const SizedBox(height: 24),
              
              // Tax Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total VAT Collected (12%):',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(summary['totalTax']),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildPaymentMethodCard(String method, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }

  void _showPaymentDialog(Order order) {
    ref.read(paymentProvider.notifier).selectOrder(order);
    
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(order: order),
    );
  }

  void _showVoidDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => VoidOrderDialog(order: order),
    );
  }

  Future<void> _approveOrder(Order order) async {
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;

    ref.read(paymentProvider.notifier).selectOrder(order);
    
    final success = await ref.read(paymentProvider.notifier).approveOrder(
      currentUser.id,
      currentUser.displayName,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.id} approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshAllData();
    } else {
      final error = ref.read(paymentProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve order: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshAllData() {
    ref.refresh(pendingOrdersProvider);
    ref.refresh(approvedOrdersProvider);
    setState(() {}); // Refresh daily summary
  }
}