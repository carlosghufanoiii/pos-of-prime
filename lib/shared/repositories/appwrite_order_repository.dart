import '../models/order.dart';
import '../services/appwrite_database_service.dart';

/// Appwrite-based order repository implementation
class AppwriteOrderRepository {
  /// Create a new order
  Future<bool> createOrder(Order order) async {
    try {
      await AppwriteDatabaseService.createOrder(order);
      return true;
    } catch (e) {
      print('Failed to create order: $e');
      return false;
    }
  }

  /// Get all pending orders waiting for cashier approval
  Future<List<Order>> getPendingOrders() async {
    try {
      return await AppwriteDatabaseService.getOrdersByStatus(OrderStatus.pendingApproval);
    } catch (e) {
      print('Failed to get pending orders: $e');
      return [];
    }
  }

  /// Get all approved orders
  Future<List<Order>> getApprovedOrders() async {
    try {
      final approvedOrders = await AppwriteDatabaseService.getOrdersByStatus(OrderStatus.approved);
      final inPrepOrders = await AppwriteDatabaseService.getOrdersByStatus(OrderStatus.inPrep);
      final readyOrders = await AppwriteDatabaseService.getOrdersByStatus(OrderStatus.ready);
      final servedOrders = await AppwriteDatabaseService.getOrdersByStatus(OrderStatus.served);
      
      return [...approvedOrders, ...inPrepOrders, ...readyOrders, ...servedOrders];
    } catch (e) {
      print('Failed to get approved orders: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final orders = await AppwriteDatabaseService.getOrders();
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      print('Failed to get order by ID: $e');
      return null;
    }
  }

  /// Approve an order (cashier function)
  Future<bool> approveOrder(String orderId, String cashierId, String cashierName) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.approved,
        cashierId: cashierId,
        cashierName: cashierName,
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to approve order: $e');
      return false;
    }
  }

  /// Process payment for an order (cashier function)
  Future<bool> processPayment(
    String orderId,
    PaymentMethod paymentMethod,
    String cashierId,
    String cashierName,
    double? amountReceived,
  ) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.served,
        paymentMethod: paymentMethod,
        cashierId: cashierId,
        cashierName: cashierName,
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to process payment: $e');
      return false;
    }
  }

  /// Void an order
  Future<bool> voidOrder(String orderId, String reason, String cashierId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.voided,
        notes: '${order.notes ?? ''}\nVoided: $reason',
        cashierId: cashierId,
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to void order: $e');
      return false;
    }
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      return await AppwriteDatabaseService.getOrdersByStatus(status);
    } catch (e) {
      print('Failed to get orders by status: $e');
      return [];
    }
  }

  /// Get all orders for cashier view
  Future<List<Order>> getCashierOrders() async {
    try {
      return await AppwriteDatabaseService.getOrders();
    } catch (e) {
      print('Failed to get cashier orders: $e');
      return [];
    }
  }

  /// Get daily summary for reporting
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final orders = await AppwriteDatabaseService.getOrders();
      final today = DateTime.now();
      final todayOrders = orders.where((order) {
        return order.createdAt.year == today.year &&
               order.createdAt.month == today.month &&
               order.createdAt.day == today.day;
      }).toList();

      final totalOrders = todayOrders.length;
      final totalRevenue = todayOrders.fold<double>(0, (sum, order) => sum + order.total);
      final paidOrders = todayOrders.where((order) => order.status == OrderStatus.served).length;

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'paidOrders': paidOrders,
        'pendingOrders': todayOrders.where((order) => order.status == OrderStatus.pendingApproval).length,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      };
    } catch (e) {
      print('Failed to get daily summary: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'paidOrders': 0,
        'pendingOrders': 0,
        'averageOrderValue': 0.0,
      };
    }
  }

  /// Kitchen operations - Start order preparation
  Future<bool> startPreparation(String orderId, String kitchenStaffId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.inPrep,
        notes: '${order.notes ?? ''}\nPreparation started by: $kitchenStaffId',
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to start preparation: $e');
      return false;
    }
  }

  /// Kitchen operations - Mark order as ready
  Future<bool> markOrderReady(String orderId, String kitchenStaffId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.ready,
        notes: '${order.notes ?? ''}\nMarked ready by: $kitchenStaffId',
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to mark order ready: $e');
      return false;
    }
  }

  /// Waiter operations - Mark order as served
  Future<bool> markOrderServed(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: OrderStatus.served,
        notes: '${order.notes ?? ''}\nServed at: ${DateTime.now()}',
      );

      await AppwriteDatabaseService.updateOrder(updatedOrder);
      return true;
    } catch (e) {
      print('Failed to mark order as served: $e');
      return false;
    }
  }
}