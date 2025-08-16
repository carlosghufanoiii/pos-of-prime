import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/realtime_order_provider.dart';
import '../../../shared/services/order_service.dart';

// Kitchen orders providers (now using realtime)
final kitchenOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      // Kitchen orders are approved orders that need preparation
      final kitchenOrders = orders.where((order) => 
        order.status == OrderStatus.approved ||
        order.status == OrderStatus.inPrep ||
        order.status == OrderStatus.ready
      ).toList();
      return AsyncValue.data(kitchenOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final inPrepOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final inPrepOrders = orders.where((order) => order.status == OrderStatus.inPrep).toList();
      return AsyncValue.data(inPrepOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final readyOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final readyOrders = orders.where((order) => order.status == OrderStatus.ready).toList();
      return AsyncValue.data(readyOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Kitchen statistics provider
final kitchenStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final kitchenOrders = orders.where((order) => 
        order.status == OrderStatus.approved ||
        order.status == OrderStatus.inPrep ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.served
      ).toList();
      
      // Calculate today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Filter today's orders
      final todaysKitchenOrders = kitchenOrders.where((order) => 
        order.createdAt.isAfter(todayStart) && order.createdAt.isBefore(todayEnd)
      ).toList();
      
      // Calculate average prep time (simplified to 12 minutes average for kitchen)
      final averagePrepTime = kitchenOrders.isNotEmpty ? 12.0 : 0.0;
      
      final stats = {
        'totalOrders': kitchenOrders.length,
        'pendingOrders': kitchenOrders.where((o) => o.status == OrderStatus.approved).length,
        'inPrepOrders': kitchenOrders.where((o) => o.status == OrderStatus.inPrep).length,
        'readyOrders': kitchenOrders.where((o) => o.status == OrderStatus.ready).length,
        'completedToday': todaysKitchenOrders.where((o) => o.status == OrderStatus.served).length,
        'averagePrepTime': averagePrepTime,
        'totalOrdersToday': todaysKitchenOrders.length,
      };
      
      return AsyncValue.data(stats);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Order status update provider
final orderStatusProvider = StateNotifierProvider<OrderStatusNotifier, OrderStatusState>((ref) {
  return OrderStatusNotifier();
});

class OrderStatusState {
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  const OrderStatusState({
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  OrderStatusState copyWith({
    bool? isUpdating,
    String? error,
    String? successMessage,
  }) {
    return OrderStatusState(
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      successMessage: successMessage,
    );
  }
}

class OrderStatusNotifier extends StateNotifier<OrderStatusState> {
  OrderStatusNotifier() : super(const OrderStatusState());

  Future<bool> startPreparation(String orderId, String kitchenStaffId) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final success = await OrderService.startPreparation(orderId, kitchenStaffId);
      
      if (success) {
        state = state.copyWith(
          isUpdating: false,
          successMessage: 'Order preparation started',
        );
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to start preparation',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> markOrderReady(String orderId, String kitchenStaffId) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final success = await OrderService.markOrderReady(orderId, kitchenStaffId);
      
      if (success) {
        state = state.copyWith(
          isUpdating: false,
          successMessage: 'Order marked as ready',
        );
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to mark order as ready',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // TODO: Implement delay order functionality in Appwrite
  Future<bool> delayOrder(String orderId, String reason, int estimatedMinutes) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      // For now, this functionality is not implemented in Appwrite
      // This method exists for future implementation
      state = state.copyWith(
        isUpdating: false,
        error: 'Delay order functionality not yet implemented',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}