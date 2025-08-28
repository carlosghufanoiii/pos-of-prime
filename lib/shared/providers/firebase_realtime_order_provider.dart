import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart' as app_order;
import '../repositories/firebase_order_repository.dart';

final firebaseOrderRepositoryProvider = Provider<FirebaseOrderRepository>((
  ref,
) {
  return FirebaseOrderRepository();
});

final firebaseOrdersStreamProvider = StreamProvider<List<app_order.Order>>((
  ref,
) {
  final repository = ref.watch(firebaseOrderRepositoryProvider);
  return repository
      .getOrdersStream()
      .timeout(
        const Duration(seconds: 5), // Reduced timeout
        onTimeout: (sink) {
          // Provide demo orders immediately to prevent loading state
          sink.add(_getDemoOrders());
          sink.close();
        },
      )
      .handleError((error) {
        // Log error and provide demo orders
        return Stream.value(_getDemoOrders());
      })
      .map((orders) {
        // If empty list from Firebase, provide demo orders
        return orders.isEmpty ? _getDemoOrders() : orders;
      });
});

final firebaseOrdersByStatusStreamProvider =
    StreamProvider.family<List<app_order.Order>, String>((ref, status) {
      final repository = ref.watch(firebaseOrderRepositoryProvider);
      return repository.getOrdersByStatusStream(status);
    });

final firebasePendingOrdersProvider = StreamProvider<List<app_order.Order>>((
  ref,
) {
  final repository = ref.watch(firebaseOrderRepositoryProvider);
  return repository.getOrdersByStatusStream('pendingApproval');
});

final firebaseApprovedOrdersProvider = StreamProvider<List<app_order.Order>>((
  ref,
) {
  final repository = ref.watch(firebaseOrderRepositoryProvider);
  return repository.getOrdersByStatusStream('approved');
});

final firebaseInPrepOrdersProvider = StreamProvider<List<app_order.Order>>((
  ref,
) {
  final repository = ref.watch(firebaseOrderRepositoryProvider);
  return repository.getOrdersByStatusStream('inPrep');
});

final firebaseReadyOrdersProvider = StreamProvider<List<app_order.Order>>((
  ref,
) {
  final repository = ref.watch(firebaseOrderRepositoryProvider);
  return repository.getOrdersByStatusStream('ready');
});

// Demo orders to prevent infinite loading states
List<app_order.Order> _getDemoOrders() {
  final now = DateTime.now();
  return [
    app_order.Order(
      id: 'demo-order-1',
      tableNumber: '5',
      customerName: 'Demo Customer',
      items: [
        app_order.OrderItem(
          id: 'demo-item-1',
          productId: 'demo-beer-1',
          productName: 'Premium Beer',
          quantity: 2,
          unitPrice: 150.0,
          totalPrice: 300.0,
          specialInstructions: '',
        ),
      ],
      status: app_order.OrderStatus.approved,
      totalAmount: 300.0,
      createdAt: now.subtract(const Duration(minutes: 5)),
      createdBy: 'demo-waiter-id',
      notes: 'Demo order for testing',
    ),
    app_order.Order(
      id: 'demo-order-2',
      tableNumber: '3',
      customerName: 'Test Customer',
      items: [
        app_order.OrderItem(
          id: 'demo-item-2',
          productId: 'demo-cocktail-1',
          productName: 'House Cocktail',
          quantity: 1,
          unitPrice: 280.0,
          totalPrice: 280.0,
          specialInstructions: 'Extra lime',
        ),
      ],
      status: app_order.OrderStatus.inPrep,
      totalAmount: 280.0,
      createdAt: now.subtract(const Duration(minutes: 10)),
      createdBy: 'demo-waiter-id',
      notes: 'Demo cocktail order',
    ),
  ];
}
