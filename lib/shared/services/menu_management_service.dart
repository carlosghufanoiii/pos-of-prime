import '../models/menu_category.dart';
import '../models/product.dart';
import '../repositories/menu_category_repository.dart';
import '../repositories/firebase_product_repository.dart';

/// Service for managing menu categories and products
class MenuManagementService {
  static final MenuCategoryRepository _categoryRepo = MenuCategoryRepository();
  static final FirebaseProductRepository _productRepo =
      FirebaseProductRepository();

  // ============ Category Management ============

  /// Get all menu categories
  static Future<List<MenuCategory>> getAllCategories() async {
    try {
      return await _categoryRepo.getAllCategories();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get categories by type (Food or Alcohol)
  static Future<List<MenuCategory>> getCategoriesByType(
    CategoryType type,
  ) async {
    try {
      return await _categoryRepo.getCategoriesByType(type);
    } catch (e) {
      throw Exception('Failed to get categories by type: $e');
    }
  }

  /// Create a new menu category
  static Future<bool> createCategory(MenuCategory category) async {
    try {
      return await _categoryRepo.createCategory(category);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing menu category
  static Future<bool> updateCategory(MenuCategory category) async {
    try {
      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      return await _categoryRepo.updateCategory(updatedCategory);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a menu category
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      // Check if category has products
      final products = await getProductsByCategory(categoryId);
      if (products.isNotEmpty) {
        throw Exception(
          'Cannot delete category with existing products. Move or delete products first.',
        );
      }
      return await _categoryRepo.deleteCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Reorder categories
  static Future<bool> reorderCategories(List<MenuCategory> categories) async {
    try {
      return await _categoryRepo.reorderCategories(categories);
    } catch (e) {
      throw Exception('Failed to reorder categories: $e');
    }
  }

  /// Initialize default categories if none exist
  static Future<bool> initializeDefaultCategories() async {
    try {
      return await _categoryRepo.initializeDefaultCategories();
    } catch (e) {
      throw Exception('Failed to initialize default categories: $e');
    }
  }

  // ============ Product Management ============

  /// Get all products
  static Future<List<Product>> getAllProducts() async {
    try {
      return await _productRepo.getAllProducts();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get products by category
  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final allProducts = await _productRepo.getAllProducts();
      return allProducts
          .where((product) => product.category == categoryId)
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  /// Get products by preparation area (Kitchen or Bar)
  static Future<List<Product>> getProductsByPreparationArea(
    PreparationArea area,
  ) async {
    try {
      final allProducts = await _productRepo.getAllProducts();
      return allProducts
          .where((product) => product.preparationArea == area)
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by preparation area: $e');
    }
  }

  /// Create a new product (optimized)
  static Future<bool> createProduct(Product product) async {
    try {
      // Skip category validation if product already has correct flags set
      if (product.preparationArea != null && product.isAlcoholic != null) {
        await _productRepo.createProduct(product);
        return true;
      }
      
      // Only validate if needed
      final category = await _categoryRepo.getCategoryById(product.category);
      if (category == null) {
        throw Exception('Invalid category ID: ${product.category}');
      }

      // Set preparation area based on category type
      final updatedProduct = product.copyWith(
        preparationArea: category.type == CategoryType.alcohol
            ? PreparationArea.bar
            : PreparationArea.kitchen,
        isAlcoholic: category.type == CategoryType.alcohol,
      );

      await _productRepo.createProduct(updatedProduct);
      return true;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update an existing product
  static Future<bool> updateProduct(Product product) async {
    try {
      // Validate category exists
      final category = await _categoryRepo.getCategoryById(product.category);
      if (category == null) {
        throw Exception('Invalid category ID: ${product.category}');
      }

      // Update preparation area and alcohol flag based on category type
      final updatedProduct = product.copyWith(
        preparationArea: category.type == CategoryType.alcohol
            ? PreparationArea.bar
            : PreparationArea.kitchen,
        isAlcoholic: category.type == CategoryType.alcohol,
        updatedAt: DateTime.now(),
      );

      await _productRepo.updateProduct(updatedProduct);
      return true;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete a product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _productRepo.deleteProduct(productId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ============ Menu Organization ============

  /// Get organized menu structure (categories with their products)
  static Future<Map<MenuCategory, List<Product>>> getMenuStructure() async {
    try {
      final categories = await getAllCategories();
      final products = await getAllProducts();

      final Map<MenuCategory, List<Product>> menuStructure = {};

      for (final category in categories) {
        final categoryProducts = products
            .where(
              (product) => product.category == category.id && product.isActive,
            )
            .toList();
        menuStructure[category] = categoryProducts;
      }

      return menuStructure;
    } catch (e) {
      throw Exception('Failed to get menu structure: $e');
    }
  }

  /// Get menu structure by type (Food or Alcohol)
  static Future<Map<MenuCategory, List<Product>>> getMenuStructureByType(
    CategoryType type,
  ) async {
    try {
      final categories = await getCategoriesByType(type);
      final products = await getAllProducts();

      final Map<MenuCategory, List<Product>> menuStructure = {};

      for (final category in categories) {
        final categoryProducts = products
            .where(
              (product) => product.category == category.id && product.isActive,
            )
            .toList();
        menuStructure[category] = categoryProducts;
      }

      return menuStructure;
    } catch (e) {
      throw Exception('Failed to get menu structure by type: $e');
    }
  }

  /// Move product to different category
  static Future<bool> moveProductToCategory(
    String productId,
    String newCategoryId,
  ) async {
    try {
      final product = await _productRepo.getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      final updatedProduct = product.copyWith(
        category: newCategoryId,
        updatedAt: DateTime.now(),
      );

      return await updateProduct(updatedProduct);
    } catch (e) {
      throw Exception('Failed to move product to category: $e');
    }
  }

  /// Get category statistics
  static Future<Map<String, dynamic>> getCategoryStats(
    String categoryId,
  ) async {
    try {
      final products = await getProductsByCategory(categoryId);
      final activeProducts = products.where((p) => p.isActive).length;
      final inactiveProducts = products.length - activeProducts;
      final totalValue = products.fold<double>(
        0,
        (sum, product) => sum + (product.price * product.stockQuantity),
      );
      final lowStockProducts = products
          .where((p) => p.stockQuantity <= 10)
          .length;

      return {
        'totalProducts': products.length,
        'activeProducts': activeProducts,
        'inactiveProducts': inactiveProducts,
        'totalValue': totalValue,
        'lowStockProducts': lowStockProducts,
        'averagePrice': products.isNotEmpty
            ? products.fold<double>(0, (sum, p) => sum + p.price) /
                  products.length
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get category stats: $e');
    }
  }
}
