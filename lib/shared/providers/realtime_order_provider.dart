import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../models/order.dart';
import '../services/appwrite_service.dart';
import '../services/order_service.dart';

/// Real-time order provider with Appwrite subscription capability
/// Falls back to regular polling if Appwrite is unavailable
class RealtimeOrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  RealtimeOrderNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  StreamSubscription<RealtimeMessage>? _subscription;
  Timer? _pollTimer;

  void _initialize() async {
    try {
      // Load initial orders from OrderService
      await _loadOrders();

      // Try to set up real-time subscription
      if (AppwriteService.isAvailable) {
        _subscription = AppwriteService.subscribeToOrderUpdates((message) {
          _handleRealtimeUpdate(message);
        });
        
        if (_subscription == null) {
          // If subscription failed, fall back to polling
          _startPolling();
        }
      } else {
        // Appwrite not available, use polling
        _startPolling();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      // Still try polling on error
      _startPolling();
    }
  }

  Future<void> _loadOrders() async {
    try {
      // Use OrderService which connects to Appwrite database
      final orders = await OrderService.getCashierOrders();
      state = AsyncValue.data(orders);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _startPolling() {
    // Poll every 5 seconds for updates
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadOrders();
    });
  }

  void _handleRealtimeUpdate(RealtimeMessage message) async {
    // When real-time update received, refresh from OrderService
    await _loadOrders();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// Real-time orders provider
final realtimeOrdersProvider = StateNotifierProvider<RealtimeOrderNotifier, AsyncValue<List<Order>>>((ref) {
  return RealtimeOrderNotifier();
});

/// Real-time pending orders provider
final realtimePendingOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final pendingOrders = orders.where((order) => order.status == OrderStatus.pendingApproval).toList();
      return AsyncValue.data(pendingOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Real-time ready orders provider
final realtimeReadyOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
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

/// Real-time approved orders provider (for kitchen)
final realtimeApprovedOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(realtimeOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final approvedOrders = orders.where((order) => 
          order.status == OrderStatus.approved ||
          order.status == OrderStatus.inPrep ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.served
      ).toList();
      return AsyncValue.data(approvedOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});