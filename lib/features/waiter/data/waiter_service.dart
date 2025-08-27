import '../../../shared/models/order.dart';
import '../../../shared/models/product.dart';
import '../../../shared/services/order_service.dart';

/// Waiter service for managing orders and service operations
class WaiterService {
  /// Get all ready orders that need to be served by waiters
  /// This includes orders that are ready from kitchen and/or bar
  static Future<List<Order>> getReadyOrders() async {
    try {
      return await OrderService.getOrdersByStatus(OrderStatus.ready);
    } catch (e) {
      throw Exception('Failed to get ready orders: $e');
    }
  }

  /// Get ready orders for a specific waiter
  static Future<List<Order>> getReadyOrdersForWaiter(String waiterId) async {
    try {
      final readyOrders = await getReadyOrders();
      return readyOrders.where((order) => order.waiterId == waiterId).toList();
    } catch (e) {
      throw Exception('Failed to get waiter ready orders: $e');
    }
  }

  /// Get all ready orders (for all waiters - useful for team visibility)
  static Future<List<Order>> getAllReadyOrders() async {
    try {
      return await getReadyOrders();
    } catch (e) {
      throw Exception('Failed to get all ready orders: $e');
    }
  }

  /// Mark an order as served by the waiter
  static Future<bool> markOrderServed(String orderId, String waiterId) async {
    try {
      // Get the order first to validate it's ready
      final order = await OrderService.getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.status != OrderStatus.ready) {
        throw Exception(
          'Order is not ready to be served. Current status: ${order.status}',
        );
      }

      // Only the original waiter should be able to mark it as served
      if (order.waiterId != waiterId) {
        throw Exception(
          'Only the original waiter can mark this order as served',
        );
      }

      // Mark as served through the cashier repository (since it has the serve functionality)
      return await _markOrderAsServed(orderId);
    } catch (e) {
      throw Exception('Failed to mark order as served: $e');
    }
  }

  /// Internal helper to mark order as served
  static Future<bool> _markOrderAsServed(String orderId) async {
    // We need to add this functionality to the OrderService and cashier repository
    // For now, let's add it to the OrderService
    return await OrderService.markOrderServed(orderId);
  }

  /// Get order details for display
  static Future<Order?> getOrderDetails(String orderId) async {
    try {
      return await OrderService.getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to get order details: $e');
    }
  }

  /// Check if an order has items ready from kitchen
  static bool hasKitchenItems(Order order) {
    return order.items.any(
      (item) => item.product.preparationArea == PreparationArea.kitchen,
    );
  }

  /// Check if an order has items ready from bar
  static bool hasBarItems(Order order) {
    return order.items.any(
      (item) => item.product.preparationArea == PreparationArea.bar,
    );
  }

  /// Get order preparation summary
  static Map<String, dynamic> getOrderPreparationSummary(Order order) {
    final kitchenItems = order.items
        .where(
          (item) => item.product.preparationArea == PreparationArea.kitchen,
        )
        .toList();
    final barItems = order.items
        .where((item) => item.product.preparationArea == PreparationArea.bar)
        .toList();
    final noPrepItems = order.items
        .where((item) => item.product.preparationArea == PreparationArea.none)
        .toList();

    return {
      'hasKitchenItems': kitchenItems.isNotEmpty,
      'hasBarItems': barItems.isNotEmpty,
      'hasNoPrepItems': noPrepItems.isNotEmpty,
      'kitchenItemsCount': kitchenItems.length,
      'barItemsCount': barItems.length,
      'noPrepItemsCount': noPrepItems.length,
      'totalItems': order.items.length,
      'kitchenItems': kitchenItems,
      'barItems': barItems,
      'noPrepItems': noPrepItems,
    };
  }
}
