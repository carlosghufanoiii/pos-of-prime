import '../models/product.dart';
import '../services/appwrite_database_service.dart';

/// Appwrite-based product repository implementation
class AppwriteProductRepository {
  
  /// Get all products
  Future<List<Product>> getProducts() async {
    try {
      return await AppwriteDatabaseService.getProducts();
    } catch (e) {
      print('Failed to get products: $e');
      return [];
    }
  }

  /// Get active products only
  Future<List<Product>> getActiveProducts() async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.where((product) => product.isActive).toList();
    } catch (e) {
      print('Failed to get active products: $e');
      return [];
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.where((product) => 
        product.category.toLowerCase() == category.toLowerCase() && product.isActive
      ).toList();
    } catch (e) {
      print('Failed to get products by category: $e');
      return [];
    }
  }

  /// Get products by preparation area
  Future<List<Product>> getProductsByPreparationArea(PreparationArea area) async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.where((product) => 
        product.preparationArea == area && product.isActive
      ).toList();
    } catch (e) {
      print('Failed to get products by preparation area: $e');
      return [];
    }
  }

  /// Search products by name
  Future<List<Product>> searchProducts(String query) async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.where((product) => 
        product.name.toLowerCase().contains(query.toLowerCase()) && product.isActive
      ).toList();
    } catch (e) {
      print('Failed to search products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      print('Failed to get product by ID: $e');
      return null;
    }
  }

  /// Get product by SKU
  Future<Product?> getProductBySku(String sku) async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.firstWhere((product) => product.sku == sku);
    } catch (e) {
      print('Failed to get product by SKU: $e');
      return null;
    }
  }

  /// Create new product
  Future<Product?> createProduct(Product product) async {
    try {
      return await AppwriteDatabaseService.createProduct(product);
    } catch (e) {
      print('Failed to create product: $e');
      return null;
    }
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      final categories = products
          .where((product) => product.isActive)
          .map((product) => product.category)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Failed to get categories: $e');
      return [];
    }
  }

  /// Check if product is in stock
  Future<bool> isInStock(String productId) async {
    try {
      final product = await getProductById(productId);
      return product?.isInStock ?? false;
    } catch (e) {
      print('Failed to check stock: $e');
      return false;
    }
  }

  /// Get low stock products (less than 10 items)
  Future<List<Product>> getLowStockProducts() async {
    try {
      final products = await AppwriteDatabaseService.getProducts();
      return products.where((product) => 
        product.isActive && product.stockQuantity < 10
      ).toList();
    } catch (e) {
      print('Failed to get low stock products: $e');
      return [];
    }
  }
}