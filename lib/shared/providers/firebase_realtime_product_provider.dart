import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/firebase_product_repository.dart';

final firebaseProductRepositoryProvider = Provider<FirebaseProductRepository>((
  ref,
) {
  return FirebaseProductRepository();
});

final firebaseProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(firebaseProductRepositoryProvider);
  return repository.getProductsStream();
});

final firebaseActiveProductsProvider = StreamProvider<List<Product>>((ref) {
  final productsAsync = ref.watch(firebaseProductsStreamProvider);
  return productsAsync.when(
    data: (products) =>
        Stream.value(products.where((p) => p.isActive).toList()),
    loading: () => const Stream.empty(),
    error: (error, stack) => Stream.error(error, stack),
  );
});

final firebaseProductsByCategoryProvider =
    StreamProvider.family<List<Product>, String>((ref, category) {
      final productsAsync = ref.watch(firebaseProductsStreamProvider);
      return productsAsync.when(
        data: (products) => Stream.value(
          products.where((p) => p.isActive && p.category == category).toList(),
        ),
        loading: () => const Stream.empty(),
        error: (error, stack) => Stream.error(error, stack),
      );
    });
