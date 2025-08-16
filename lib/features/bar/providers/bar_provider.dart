import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/realtime_order_provider.dart';
import '../../../shared/services/order_service.dart';

// Bar orders providers (now using realtime)
final barOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      // Bar orders are drinks that need preparation
      final barOrders = orders.where((order) => 
        order.status == OrderStatus.approved ||
        order.status == OrderStatus.inPrep ||
        order.status == OrderStatus.ready
      ).where((order) => 
        order.items.any((item) => item.product.preparationArea == PreparationArea.bar)
      ).toList();
      return AsyncValue.data(barOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final barInPrepOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final inPrepOrders = orders.where((order) => 
        order.status == OrderStatus.inPrep &&
        order.items.any((item) => item.product.preparationArea == PreparationArea.bar)
      ).toList();
      return AsyncValue.data(inPrepOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final barReadyOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final readyOrders = orders.where((order) => 
        order.status == OrderStatus.ready &&
        order.items.any((item) => item.product.preparationArea == PreparationArea.bar)
      ).toList();
      return AsyncValue.data(readyOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Bar statistics provider
final barStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final barOrders = orders.where((order) => 
        order.items.any((item) => item.product.preparationArea == PreparationArea.bar)
      ).toList();
      
      // Calculate today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Filter today's orders
      final todaysBarOrders = barOrders.where((order) => 
        order.createdAt.isAfter(todayStart) && order.createdAt.isBefore(todayEnd)
      ).toList();
      
      // Calculate drink type statistics
      int alcoholicDrinks = 0;
      int nonAlcoholicDrinks = 0;
      int totalDrinks = 0;
      
      for (final order in todaysBarOrders) {
        for (final item in order.items) {
          if (item.product.preparationArea == PreparationArea.bar) {
            totalDrinks += item.quantity;
            if (item.product.isAlcoholic) {
              alcoholicDrinks += item.quantity;
            } else {
              nonAlcoholicDrinks += item.quantity;
            }
          }
        }
      }
      
      // Calculate average prep time (simplified to 5 minutes average)
      final averagePrepTime = barOrders.isNotEmpty ? 5.0 : 0.0;
      
      final stats = {
        'totalOrders': barOrders.length,
        'pendingOrders': barOrders.where((o) => o.status == OrderStatus.approved).length,
        'inPrepOrders': barOrders.where((o) => o.status == OrderStatus.inPrep).length,
        'readyOrders': barOrders.where((o) => o.status == OrderStatus.ready).length,
        'completedToday': todaysBarOrders.where((o) => o.status == OrderStatus.served).length,
        'alcoholicDrinks': alcoholicDrinks,
        'nonAlcoholicDrinks': nonAlcoholicDrinks,
        'totalDrinks': totalDrinks,
        'averagePrepTime': averagePrepTime,
        'totalOrdersToday': todaysBarOrders.length,
      };
      
      return AsyncValue.data(stats);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Bar order status update provider
final barOrderStatusProvider = StateNotifierProvider<BarOrderStatusNotifier, BarOrderStatusState>((ref) {
  return BarOrderStatusNotifier();
});

class BarOrderStatusState {
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  const BarOrderStatusState({
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  BarOrderStatusState copyWith({
    bool? isUpdating,
    String? error,
    String? successMessage,
  }) {
    return BarOrderStatusState(
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      successMessage: successMessage,
    );
  }
}

class BarOrderStatusNotifier extends StateNotifier<BarOrderStatusState> {
  BarOrderStatusNotifier() : super(const BarOrderStatusState());

  Future<bool> startPreparation(String orderId, String barStaffId) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final success = await OrderService.startPreparation(orderId, barStaffId);
      
      if (success) {
        state = state.copyWith(
          isUpdating: false,
          successMessage: 'Drink preparation started',
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

  Future<bool> markDrinkReady(String orderId, String barStaffId) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      final success = await OrderService.markOrderReady(orderId, barStaffId);
      
      if (success) {
        state = state.copyWith(
          isUpdating: false,
          successMessage: 'Drinks marked as ready',
        );
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to mark drinks as ready',
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