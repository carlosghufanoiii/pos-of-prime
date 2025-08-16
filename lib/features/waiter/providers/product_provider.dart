import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/realtime_product_provider.dart';

// All products provider (now realtime)
final productsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(realtimeProductsProvider);
});

// Active products provider (now realtime)
final activeProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(realtimeActiveProductsProvider);
});

// Products by category provider (now realtime)
final productsByCategoryProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, category) {
  return ref.watch(realtimeProductsByCategoryProvider(category));
});

// Product search provider (search in realtime data)
final productSearchProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, query) {
  final productsAsync = ref.watch(realtimeProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      if (query.isEmpty) {
        return AsyncValue.data(products.where((p) => p.isActive).toList());
      }
      
      final searchResults = products
          .where((product) => 
              product.isActive &&
              (product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.category.toLowerCase().contains(query.toLowerCase()) ||
               product.sku.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      return AsyncValue.data(searchResults);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Product categories provider (now realtime)
final productCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(realtimeProductCategoriesProvider);
});

// Selected category state provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered products provider (combines category filter and search)
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  if (searchQuery.isNotEmpty) {
    return ref.watch(productSearchProvider(searchQuery));
  } else if (selectedCategory != null) {
    return ref.watch(productsByCategoryProvider(selectedCategory));
  } else {
    return ref.watch(activeProductsProvider);
  }
});