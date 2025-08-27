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
  return repository.getOrdersStream();
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
