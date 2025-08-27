import '../models/product.dart';
import '../services/firebase_database_service.dart';

class FirebaseProductRepository {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  Future<void> createProduct(Product product) async {
    await _dbService.createProduct(product);
  }

  Future<Product?> getProduct(String productId) async {
    return await _dbService.getProduct(productId);
  }

  Future<void> updateProduct(Product product) async {
    await _dbService.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _dbService.deleteProduct(productId);
  }

  Future<List<Product>> getAllProducts() async {
    return await _dbService.getAllProducts();
  }

  Stream<List<Product>> getProductsStream() {
    return _dbService.getProductsStream();
  }

  Future<void> updateInventoryBatch(List<Product> products) async {
    await _dbService.updateInventoryBatch(products);
  }

  // Additional business methods
  Future<List<Product>> getProducts() async {
    return await getAllProducts();
  }

  Future<List<Product>> getActiveProducts() async {
    return await getAllProducts();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getAllProducts();
    return products.where((p) => p.category == category).toList();
  }

  Future<List<Product>> getProductsByPreparationArea(dynamic area) async {
    final products = await getAllProducts();
    if (area is PreparationArea) {
      return products.where((p) => p.preparationArea == area).toList();
    } else if (area is String) {
      return products
          .where((p) => p.preparationArea.displayName == area)
          .toList();
    }
    return products;
  }

  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  Future<Product?> getProductById(String productId) async {
    return await getProduct(productId);
  }

  Future<List<String>> getCategories() async {
    final products = await getAllProducts();
    return products.map((p) => p.category).toSet().toList();
  }

  Future<bool> isInStock(String productId) async {
    final product = await getProduct(productId);
    return product != null && product.stockQuantity > 0;
  }

  Future<List<Product>> getLowStockProducts() async {
    final products = await getAllProducts();
    const lowStockThreshold = 5; // Default threshold
    return products.where((p) => p.stockQuantity <= lowStockThreshold).toList();
  }
}
