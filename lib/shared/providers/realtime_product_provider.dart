import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../models/product.dart';
import '../services/appwrite_service.dart';
import '../services/product_service.dart';

/// Real-time product provider with Appwrite subscription capability
/// Falls back to regular polling if Appwrite is unavailable
class RealtimeProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  RealtimeProductNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  StreamSubscription<RealtimeMessage>? _subscription;
  Timer? _pollTimer;

  void _initialize() async {
    try {
      // Load initial products from ProductService
      await _loadProducts();

      // Try to set up real-time subscription
      if (AppwriteService.isAvailable) {
        _subscription = AppwriteService.subscribeToProductUpdates((message) {
          print('📦 Product realtime update received: ${message.events}');
          _handleRealtimeUpdate(message);
        });
        
        if (_subscription == null) {
          // If subscription failed, fall back to polling
          print('📦 Product subscription failed, falling back to polling');
          _startPolling();
        } else {
          print('📦 Product realtime subscription active');
        }
      } else {
        // Appwrite not available, use polling
        print('📦 Appwrite not available, using polling for products');
        _startPolling();
      }
    } catch (e, stackTrace) {
      print('📦 Product provider initialization failed: $e');
      state = AsyncValue.error(e, stackTrace);
      // Still try polling on error
      _startPolling();
    }
  }

  Future<void> _loadProducts() async {
    try {
      // Use ProductService which uses Appwrite when available
      final products = await ProductService.getProducts();
      print('📦 Loaded ${products.length} products');
      state = AsyncValue.data(products);
    } catch (e, stackTrace) {
      print('📦 Failed to load products: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _startPolling() {
    // Poll every 10 seconds for product updates (less frequent than orders)
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      print('📦 Polling for product updates...');
      _loadProducts();
    });
  }

  void _handleRealtimeUpdate(RealtimeMessage message) async {
    print('📦 Processing product realtime update: ${message.events}');
    // When real-time update received, refresh from ProductService
    await _loadProducts();
  }

  /// Manually refresh products (for pull-to-refresh)
  Future<void> refresh() async {
    print('📦 Manual product refresh requested');
    await _loadProducts();
  }

  @override
  void dispose() {
    print('📦 Disposing product realtime provider');
    _subscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// Real-time products provider
final realtimeProductsProvider = StateNotifierProvider<RealtimeProductNotifier, AsyncValue<List<Product>>>((ref) {
  return RealtimeProductNotifier();
});

/// Real-time active products provider
final realtimeActiveProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(realtimeProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final activeProducts = products.where((product) => product.isActive).toList();
      return AsyncValue.data(activeProducts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Real-time products by category provider
final realtimeProductsByCategoryProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, category) {
  final productsAsync = ref.watch(realtimeProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final categoryProducts = products
          .where((product) => product.category == category && product.isActive)
          .toList();
      return AsyncValue.data(categoryProducts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Real-time product categories provider
final realtimeProductCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final productsAsync = ref.watch(realtimeProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final categories = products
          .where((product) => product.isActive)
          .map((product) => product.category)
          .toSet()
          .toList();
      return AsyncValue.data(categories);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Real-time low stock products provider
final realtimeLowStockProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(realtimeProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final lowStockProducts = products
          .where((product) => product.isActive && product.stockQuantity < 10)
          .toList();
      return AsyncValue.data(lowStockProducts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Manual refresh function for products
final refreshProductsProvider = Provider((ref) {
  return () {
    final notifier = ref.read(realtimeProductsProvider.notifier);
    return notifier.refresh();
  };
});