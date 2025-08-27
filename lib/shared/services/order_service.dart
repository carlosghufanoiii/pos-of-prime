import '../models/order.dart';
import '../repositories/firebase_order_repository.dart';

/// Shared order service for managing orders across the application
/// This service coordinates between different modules (waiter, cashier, kitchen, bar)
/// Uses Firebase database exclusively
class OrderService {
  static final FirebaseOrderRepository _repository = FirebaseOrderRepository();

  /// Create a new order and add it to the system
  /// This is typically called by waiters when they submit orders
  static Future<bool> createOrder(Order order) async {
    try {
      return await _repository.createOrderWithResult(order);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get all pending orders waiting for cashier approval
  static Future<List<Order>> getPendingOrders() async {
    try {
      return await _repository.getPendingOrders();
    } catch (e) {
      throw Exception('Failed to get pending orders: $e');
    }
  }

  /// Get all approved orders
  static Future<List<Order>> getApprovedOrders() async {
    try {
      return await _repository.getApprovedOrders();
    } catch (e) {
      throw Exception('Failed to get approved orders: $e');
    }
  }

  /// Get order by ID
  static Future<Order?> getOrderById(String orderId) async {
    try {
      return await _repository.getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Approve an order (cashier function)
  static Future<bool> approveOrder(
    String orderId,
    String cashierId,
    String cashierName,
  ) async {
    try {
      return await _repository.approveOrder(orderId, cashierId, cashierName);
    } catch (e) {
      throw Exception('Failed to approve order: $e');
    }
  }

  /// Process payment for an order (cashier function)
  static Future<bool> processPayment(
    String orderId,
    PaymentMethod paymentMethod,
    String cashierId,
    String cashierName,
    double? amountReceived,
  ) async {
    try {
      return await _repository.processPayment(
        orderId,
        paymentMethod,
        cashierId,
        cashierName,
        amountReceived,
      );
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Void an order
  static Future<bool> voidOrder(
    String orderId,
    String reason,
    String cashierId,
  ) async {
    try {
      return await _repository.voidOrder(orderId, reason, cashierId);
    } catch (e) {
      throw Exception('Failed to void order: $e');
    }
  }

  /// Get orders by status
  static Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      return await _repository.getOrdersByStatus(status.name);
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  /// Get all orders for cashier view
  static Future<List<Order>> getCashierOrders() async {
    try {
      return await _repository.getCashierOrders();
    } catch (e) {
      throw Exception('Failed to get cashier orders: $e');
    }
  }

  /// Get daily summary for reporting
  static Future<Map<String, dynamic>> getDailySummary() async {
    try {
      return await _repository.getDailySummary();
    } catch (e) {
      throw Exception('Failed to get daily summary: $e');
    }
  }

  /// Kitchen operations - Start order preparation
  static Future<bool> startPreparation(
    String orderId,
    String kitchenStaffId,
  ) async {
    try {
      return await _repository.startPreparation(orderId, kitchenStaffId);
    } catch (e) {
      throw Exception('Failed to start preparation: $e');
    }
  }

  /// Kitchen operations - Mark order as ready
  static Future<bool> markOrderReady(
    String orderId,
    String kitchenStaffId,
  ) async {
    try {
      return await _repository.markOrderReady(orderId, kitchenStaffId);
    } catch (e) {
      throw Exception('Failed to mark order ready: $e');
    }
  }

  /// Waiter operations - Mark order as served
  static Future<bool> markOrderServed(String orderId) async {
    try {
      return await _repository.markOrderServed(orderId);
    } catch (e) {
      throw Exception('Failed to mark order as served: $e');
    }
  }
}
