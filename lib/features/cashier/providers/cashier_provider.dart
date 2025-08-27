import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../../../shared/services/order_service.dart';
import '../../../shared/providers/firebase_realtime_order_provider.dart';

// Pending orders provider (now realtime)
final pendingOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  return ref.watch(firebasePendingOrdersProvider);
});

// Approved orders provider (orders approved but not yet paid)
final approvedOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(firebaseOrdersStreamProvider);

  return ordersAsync.when(
    data: (orders) {
      final approvedOrders = orders
          .where((order) => order.status == OrderStatus.approved)
          .toList();
      return AsyncValue.data(approvedOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// All cashier orders provider (now realtime)
final cashierOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  return ref.watch(firebaseOrdersStreamProvider);
});

// Order filter state
enum OrderFilter { all, pending, approved, paid }

final orderFilterProvider = StateProvider<OrderFilter>(
  (ref) => OrderFilter.pending,
);

// Filtered orders provider (now realtime)
final filteredOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final filter = ref.watch(orderFilterProvider);
  final ordersAsync = ref.watch(firebaseOrdersStreamProvider);

  return ordersAsync.when(
    data: (orders) {
      List<Order> filteredOrders;

      switch (filter) {
        case OrderFilter.pending:
          filteredOrders = orders
              .where((order) => order.status == OrderStatus.pendingApproval)
              .toList();
          break;
        case OrderFilter.approved:
          filteredOrders = orders
              .where((order) => order.status == OrderStatus.approved)
              .toList();
          break;
        case OrderFilter.paid:
          filteredOrders = orders
              .where((order) => order.paymentMethod != null)
              .toList();
          break;
        case OrderFilter.all:
          filteredOrders = orders;
          break;
      }

      return AsyncValue.data(filteredOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Payment state management
class PaymentState {
  final Order? selectedOrder;
  final PaymentMethod? selectedPaymentMethod;
  final double? amountReceived;
  final double? changeAmount;
  final bool isProcessing;
  final String? error;

  const PaymentState({
    this.selectedOrder,
    this.selectedPaymentMethod,
    this.amountReceived,
    this.changeAmount,
    this.isProcessing = false,
    this.error,
  });

  PaymentState copyWith({
    Order? selectedOrder,
    PaymentMethod? selectedPaymentMethod,
    double? amountReceived,
    double? changeAmount,
    bool? isProcessing,
    String? error,
  }) {
    return PaymentState(
      selectedOrder: selectedOrder ?? this.selectedOrder,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  void selectOrder(Order order) {
    state = state.copyWith(selectedOrder: order);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void setAmountReceived(double amount) {
    final changeAmount = state.selectedOrder != null
        ? amount - state.selectedOrder!.total
        : 0.0;

    state = state.copyWith(amountReceived: amount, changeAmount: changeAmount);
  }

  Future<bool> approveOrder(String cashierId, String cashierName) async {
    if (state.selectedOrder == null) return false;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final success = await OrderService.approveOrder(
        state.selectedOrder!.id,
        cashierId,
        cashierName,
      );

      if (success) {
        state = const PaymentState(); // Reset state
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to approve order',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> processPayment(String cashierId, String cashierName) async {
    if (state.selectedOrder == null || state.selectedPaymentMethod == null) {
      return false;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final success = await OrderService.processPayment(
        state.selectedOrder!.id,
        state.selectedPaymentMethod!,
        cashierId,
        cashierName,
        state.amountReceived,
      );

      if (success) {
        state = const PaymentState(); // Reset state
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to process payment',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> voidOrder(String reason, String cashierId) async {
    if (state.selectedOrder == null) return false;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final success = await OrderService.voidOrder(
        state.selectedOrder!.id,
        reason,
        cashierId,
      );

      if (success) {
        state = const PaymentState(); // Reset state
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to void order',
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

  void resetPayment() {
    state = const PaymentState();
  }
}

// Payment provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier();
});

// Quick access providers
final selectedOrderProvider = Provider<Order?>((ref) {
  return ref.watch(paymentProvider).selectedOrder;
});

final paymentMethodProvider = Provider<PaymentMethod?>((ref) {
  return ref.watch(paymentProvider).selectedPaymentMethod;
});

final isPaymentProcessingProvider = Provider<bool>((ref) {
  return ref.watch(paymentProvider).isProcessing;
});

final paymentErrorProvider = Provider<String?>((ref) {
  return ref.watch(paymentProvider).error;
});
