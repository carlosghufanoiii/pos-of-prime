import '../models/product.dart';
import '../repositories/appwrite_product_repository.dart';

/// Shared product service for managing products across the application
/// Uses Appwrite database exclusively
class ProductService {
  static final AppwriteProductRepository _repository = AppwriteProductRepository();

  /// Get all products
  static Future<List<Product>> getProducts() async {
    try {
      return await _repository.getProducts();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get active products only
  static Future<List<Product>> getActiveProducts() async {
    try {
      return await _repository.getActiveProducts();
    } catch (e) {
      throw Exception('Failed to get active products: $e');
    }
  }

  /// Get products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await _repository.getProductsByCategory(category);
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  /// Get products by preparation area
  static Future<List<Product>> getProductsByPreparationArea(PreparationArea area) async {
    try {
      return await _repository.getProductsByPreparationArea(area);
    } catch (e) {
      throw Exception('Failed to get products by preparation area: $e');
    }
  }

  /// Search products by name
  static Future<List<Product>> searchProducts(String query) async {
    try {
      return await _repository.searchProducts(query);
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product by ID
  static Future<Product?> getProductById(String productId) async {
    try {
      return await _repository.getProductById(productId);
    } catch (e) {
      throw Exception('Failed to get product by ID: $e');
    }
  }

  /// Get categories
  static Future<List<String>> getCategories() async {
    try {
      return await _repository.getCategories();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Check if product is in stock
  static Future<bool> isInStock(String productId) async {
    try {
      return await _repository.isInStock(productId);
    } catch (e) {
      throw Exception('Failed to check stock: $e');
    }
  }

  /// Get low stock products
  static Future<List<Product>> getLowStockProducts() async {
    try {
      return await _repository.getLowStockProducts();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }
}