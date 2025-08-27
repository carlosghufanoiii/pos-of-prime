import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../data/waiter_service.dart';

// Waiter ready orders provider (orders ready for pickup/serving)
final waiterReadyOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return WaiterService.getAllReadyOrders();
});

// Ready orders for specific waiter
final waiterSpecificReadyOrdersProvider =
    FutureProvider.family<List<Order>, String>((ref, waiterId) async {
      return WaiterService.getReadyOrdersForWaiter(waiterId);
    });

// Order details provider
final orderDetailsProvider = FutureProvider.family<Order?, String>((
  ref,
  orderId,
) async {
  return WaiterService.getOrderDetails(orderId);
});

// Service state management for marking orders as served
class ServiceState {
  final bool isProcessing;
  final String? error;
  final String? lastServedOrderId;

  const ServiceState({
    this.isProcessing = false,
    this.error,
    this.lastServedOrderId,
  });

  ServiceState copyWith({
    bool? isProcessing,
    String? error,
    String? lastServedOrderId,
  }) {
    return ServiceState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastServedOrderId: lastServedOrderId ?? this.lastServedOrderId,
    );
  }
}

// Service notifier for handling serve actions
class ServiceNotifier extends StateNotifier<ServiceState> {
  ServiceNotifier() : super(const ServiceState());

  Future<bool> markOrderServed(String orderId, String waiterId) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final success = await WaiterService.markOrderServed(orderId, waiterId);

      if (success) {
        state = state.copyWith(isProcessing: false, lastServedOrderId: orderId);
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to mark order as served',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    state = const ServiceState();
  }
}

// Service provider
final serviceProvider = StateNotifierProvider<ServiceNotifier, ServiceState>((
  ref,
) {
  return ServiceNotifier();
});

// Quick access providers
final isServingProvider = Provider<bool>((ref) {
  return ref.watch(serviceProvider).isProcessing;
});

final serviceErrorProvider = Provider<String?>((ref) {
  return ref.watch(serviceProvider).error;
});

final lastServedOrderProvider = Provider<String?>((ref) {
  return ref.watch(serviceProvider).lastServedOrderId;
});
