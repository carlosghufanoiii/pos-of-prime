import '../models/order.dart' as app_order;
import '../services/firebase_database_service.dart';

class FirebaseOrderRepository {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  Future<void> createOrder(app_order.Order order) async {
    await _dbService.createOrder(order);
  }

  Future<app_order.Order?> getOrder(String orderId) async {
    return await _dbService.getOrder(orderId);
  }

  Future<void> updateOrder(app_order.Order order) async {
    await _dbService.updateOrder(order);
  }

  Future<void> deleteOrder(String orderId) async {
    await _dbService.deleteOrder(orderId);
  }

  Future<List<app_order.Order>> getAllOrders() async {
    return await _dbService.getAllOrders();
  }

  Future<List<app_order.Order>> getOrdersByStatus(String status) async {
    return await _dbService.getOrdersByStatus(status);
  }

  Stream<List<app_order.Order>> getOrdersStream() {
    return _dbService.getOrdersStream();
  }

  Stream<List<app_order.Order>> getOrdersByStatusStream(String status) {
    return _dbService.getOrdersByStatusStream(status);
  }

  // Business logic methods for service compatibility
  Future<bool> createOrderWithResult(app_order.Order order) async {
    try {
      await _dbService.createOrder(order);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<app_order.Order>> getPendingOrders() async {
    return await getOrdersByStatus('pendingApproval');
  }

  Future<List<app_order.Order>> getApprovedOrders() async {
    return await getOrdersByStatus('approved');
  }

  Future<app_order.Order?> getOrderById(String orderId) async {
    return await getOrder(orderId);
  }

  Future<bool> approveOrder(
    String orderId,
    String cashierId,
    String cashierName,
  ) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          status: app_order.OrderStatus.approved,
          cashierId: cashierId,
          cashierName: cashierName,
          approvedAt: DateTime.now(),
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> processPayment(
    String orderId,
    app_order.PaymentMethod paymentMethod,
    String cashierId,
    String cashierName,
    double? amountReceived,
  ) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          paymentMethod: paymentMethod,
          cashierId: cashierId,
          cashierName: cashierName,
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> voidOrder(
    String orderId,
    String reason,
    String cashierId,
  ) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          status: app_order.OrderStatus.voided,
          notes: '${order.notes}\nVoided: $reason',
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<app_order.Order>> getCashierOrders() async {
    return await getAllOrders();
  }

  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final orders = await getAllOrders();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayOrders = orders
          .where(
            (o) =>
                o.createdAt.isAfter(todayStart) &&
                o.createdAt.isBefore(todayEnd),
          )
          .toList();

      final paidOrders = todayOrders
          .where(
            (o) =>
                o.paymentMethod != null &&
                o.status != app_order.OrderStatus.voided,
          )
          .toList();

      final pendingOrders = todayOrders
          .where((o) => o.status == app_order.OrderStatus.pendingApproval)
          .toList();

      final voidedOrders = todayOrders
          .where((o) => o.status == app_order.OrderStatus.voided)
          .toList();

      // Calculate sales by payment method
      double cashSales = 0.0;
      double cardSales = 0.0;
      double eWalletSales = 0.0;
      double totalSales = 0.0;

      for (final order in paidOrders) {
        final orderTotal = order.total;
        totalSales += orderTotal;

        switch (order.paymentMethod) {
          case app_order.PaymentMethod.cash:
            cashSales += orderTotal;
            break;
          case app_order.PaymentMethod.card:
            cardSales += orderTotal;
            break;
          case app_order.PaymentMethod.eWallet:
            eWalletSales += orderTotal;
            break;
          default:
            break;
        }
      }

      // Calculate tax (12% VAT in Philippines)
      final totalTax = totalSales * 0.12;

      // Calculate average order value
      final averageOrderValue = paidOrders.isNotEmpty
          ? totalSales / paidOrders.length
          : 0.0;

      return {
        'date': now.toIso8601String(),
        'todayDate': '${now.day}/${now.month}/${now.year}',

        // Order counts
        'totalOrders': todayOrders.length,
        'paidOrders': paidOrders.length,
        'pendingOrders': pendingOrders.length,
        'voidedOrders': voidedOrders.length,

        // Sales data
        'totalSales': totalSales,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'eWalletSales': eWalletSales,

        // Tax information
        'totalTax': totalTax,
        'salesWithoutTax': totalSales - totalTax,

        // Analytics
        'averageOrderValue': averageOrderValue,
        'orderRate':
            todayOrders.length /
            24.0, // Orders per hour (assuming 24h operation)
        // Status breakdown
        'ordersByStatus': {
          'pendingApproval': pendingOrders.length,
          'approved': todayOrders
              .where((o) => o.status == app_order.OrderStatus.approved)
              .length,
          'inPrep': todayOrders
              .where((o) => o.status == app_order.OrderStatus.inPrep)
              .length,
          'ready': todayOrders
              .where((o) => o.status == app_order.OrderStatus.ready)
              .length,
          'served': todayOrders
              .where((o) => o.status == app_order.OrderStatus.served)
              .length,
          'voided': voidedOrders.length,
        },
      };
    } catch (e) {
      // Return default values if error occurs
      return {
        'date': DateTime.now().toIso8601String(),
        'todayDate': DateTime.now().toString().split(' ')[0],
        'totalOrders': 0,
        'paidOrders': 0,
        'pendingOrders': 0,
        'voidedOrders': 0,
        'totalSales': 0.0,
        'cashSales': 0.0,
        'cardSales': 0.0,
        'eWalletSales': 0.0,
        'totalTax': 0.0,
        'salesWithoutTax': 0.0,
        'averageOrderValue': 0.0,
        'orderRate': 0.0,
        'ordersByStatus': {
          'pendingApproval': 0,
          'approved': 0,
          'inPrep': 0,
          'ready': 0,
          'served': 0,
          'voided': 0,
        },
      };
    }
  }

  Future<bool> startPreparation(String orderId, String staffId) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          status: app_order.OrderStatus.inPrep,
          prepStartedAt: DateTime.now(),
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markOrderReady(String orderId, String staffId) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          status: app_order.OrderStatus.ready,
          readyAt: DateTime.now(),
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markOrderServed(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(
          status: app_order.OrderStatus.served,
          servedAt: DateTime.now(),
        );
        await updateOrder(updatedOrder);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
