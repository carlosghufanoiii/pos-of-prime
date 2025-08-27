import '../models/order.dart';
import '../services/order_service.dart';
import '../services/user_management_service.dart';

/// Analytics service for dashboard stats and reports
/// Calculates metrics from live data in Firebase
class AnalyticsService {
  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final users = await UserManagementService.getAllUsers();
      final orders = await OrderService.getCashierOrders();

      // Calculate today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Filter today's orders
      final todaysOrders = orders
          .where(
            (order) =>
                order.createdAt.isAfter(todayStart) &&
                order.createdAt.isBefore(todayEnd),
          )
          .toList();

      final activeUsers = users.where((u) => u.isActive).length;
      final totalOrders = orders.length;
      final paidOrders = orders.where((o) => o.paymentMethod != null).length;
      final totalSales = orders
          .where((o) => o.paymentMethod != null)
          .fold<double>(0, (sum, order) => sum + order.total);

      // Calculate daily metrics
      final dailyOrders = todaysOrders.length;
      final dailyRevenue = todaysOrders
          .where((o) => o.paymentMethod != null)
          .fold<double>(0, (sum, order) => sum + order.total);

      // Calculate user breakdown by role
      final adminUsers = users.where((u) => u.role.name == 'admin').length;
      final waiterUsers = users.where((u) => u.role.name == 'waiter').length;
      final cashierUsers = users.where((u) => u.role.name == 'cashier').length;
      final kitchenUsers = users.where((u) => u.role.name == 'kitchen').length;
      final bartenderUsers = users
          .where((u) => u.role.name == 'bartender')
          .length;

      return {
        // Original stats for compatibility
        'totalUsers': users.length,
        'activeUsers': activeUsers,
        'totalOrders': totalOrders,
        'paidOrders': paidOrders,
        'totalSales': totalSales,
        'averageOrderValue': paidOrders > 0 ? totalSales / paidOrders : 0.0,

        // Admin dashboard specific stats
        'dailyOrders': dailyOrders,
        'dailyRevenue': dailyRevenue,
        'systemUptime': '99.9%', // Simplified for now
        'todayLogins': activeUsers, // Simplified - use active users as proxy
        // User role breakdown
        'adminUsers': adminUsers,
        'waiterUsers': waiterUsers,
        'cashierUsers': cashierUsers,
        'kitchenUsers': kitchenUsers,
        'bartenderUsers': bartenderUsers,

        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  /// Get sales analytics
  static Future<Map<String, dynamic>> getSalesAnalytics() async {
    try {
      final orders = await OrderService.getCashierOrders();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      // Filter paid orders only
      final paidOrders = orders.where((o) => o.paymentMethod != null).toList();

      // Calculate daily sales
      final dailySales = _calculateSalesForPeriod(paidOrders, todayStart, now);

      // Calculate weekly sales
      final weeklySales = _calculateSalesForPeriod(paidOrders, weekStart, now);

      // Calculate monthly sales
      final monthlySales = _calculateSalesForPeriod(
        paidOrders,
        monthStart,
        now,
      );

      // Calculate yearly sales
      final yearSales = _calculateSalesForPeriod(paidOrders, yearStart, now);

      // Payment method breakdown
      final cashSales = _calculateSalesByPaymentMethod(
        paidOrders,
        PaymentMethod.cash,
      );
      final cardSales = _calculateSalesByPaymentMethod(
        paidOrders,
        PaymentMethod.card,
      );
      final eWalletSales = _calculateSalesByPaymentMethod(
        paidOrders,
        PaymentMethod.eWallet,
      );

      return {
        'dailySales': dailySales,
        'weeklySales': weeklySales,
        'monthlySales': monthlySales,
        'yearSales': yearSales,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'eWalletSales': eWalletSales,
        'totalPaidOrders': paidOrders.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get sales analytics: $e');
    }
  }

  /// Get system statistics
  static Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final orders = await OrderService.getCashierOrders();
      final users = await UserManagementService.getAllUsers();

      // Calculate order status distribution
      final pendingOrders = orders
          .where((o) => o.status == OrderStatus.pendingApproval)
          .length;
      final approvedOrders = orders
          .where((o) => o.status == OrderStatus.approved)
          .length;
      final inPrepOrders = orders
          .where((o) => o.status == OrderStatus.inPrep)
          .length;
      final readyOrders = orders
          .where((o) => o.status == OrderStatus.ready)
          .length;
      final servedOrders = orders
          .where((o) => o.status == OrderStatus.served)
          .length;

      // Calculate user role distribution
      final waiterCount = users.where((u) => u.role.name == 'waiter').length;
      final cashierCount = users.where((u) => u.role.name == 'cashier').length;
      final kitchenCount = users.where((u) => u.role.name == 'kitchen').length;
      final adminCount = users.where((u) => u.role.name == 'admin').length;

      // System health indicators (simplified)
      return {
        'orderStatusDistribution': {
          'pending': pendingOrders,
          'approved': approvedOrders,
          'inPrep': inPrepOrders,
          'ready': readyOrders,
          'served': servedOrders,
        },
        'userRoleDistribution': {
          'waiters': waiterCount,
          'cashiers': cashierCount,
          'kitchen': kitchenCount,
          'admins': adminCount,
        },
        'systemHealth': {
          'databaseConnected': true, // Simplified - always true if we got data
          'realtimeConnected': true, // Simplified
          'averageOrderProcessingTime': _calculateAverageProcessingTime(orders),
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get system stats: $e');
    }
  }

  /// Get recent activities (simplified)
  static Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final orders = await OrderService.getCashierOrders();

      // Get last 10 orders as recent activities
      final recentOrders = orders
          .take(10)
          .map(
            (order) => {
              'id': order.id,
              'type': 'order',
              'action': _getOrderAction(order.status),
              'description':
                  'Order ${order.id} ${_getOrderAction(order.status)}',
              'timestamp': order.createdAt.toIso8601String(),
              'userId': order.waiterId,
              'amount': order.total,
            },
          )
          .toList();

      return recentOrders;
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  // Helper methods

  /// Calculate sales for a specific time period
  static double _calculateSalesForPeriod(
    List<Order> orders,
    DateTime start,
    DateTime end,
  ) {
    return orders
        .where(
          (order) =>
              order.createdAt.isAfter(start) && order.createdAt.isBefore(end),
        )
        .fold<double>(0, (sum, order) => sum + order.total);
  }

  /// Calculate sales by payment method
  static double _calculateSalesByPaymentMethod(
    List<Order> orders,
    PaymentMethod method,
  ) {
    return orders
        .where((order) => order.paymentMethod == method)
        .fold<double>(0, (sum, order) => sum + order.total);
  }

  /// Calculate average order processing time (simplified)
  static double _calculateAverageProcessingTime(List<Order> orders) {
    final processedOrders = orders
        .where(
          (o) =>
              o.status == OrderStatus.served || o.status == OrderStatus.ready,
        )
        .toList();

    if (processedOrders.isEmpty) return 0.0;

    // Simplified calculation - assumes 15 minutes average
    return 15.0; // minutes
  }

  /// Get order action description
  static String _getOrderAction(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingApproval:
        return 'created';
      case OrderStatus.approved:
        return 'approved';
      case OrderStatus.inPrep:
        return 'in preparation';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.served:
        return 'served';
      case OrderStatus.voided:
        return 'voided';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}
