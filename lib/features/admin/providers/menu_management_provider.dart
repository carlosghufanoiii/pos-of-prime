import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/menu_category.dart';
import '../../../shared/models/product.dart';
import '../../../shared/services/menu_management_service.dart';

// ============ Category Providers ============

final menuCategoriesProvider = FutureProvider.autoDispose<List<MenuCategory>>((ref) async {
  return MenuManagementService.getAllCategories();
});

final foodCategoriesProvider = FutureProvider.autoDispose<List<MenuCategory>>((ref) async {
  return MenuManagementService.getCategoriesByType(CategoryType.food);
});

final alcoholCategoriesProvider = FutureProvider.autoDispose<List<MenuCategory>>((
  ref,
) async {
  return MenuManagementService.getCategoriesByType(CategoryType.alcohol);
});

// ============ Product Providers ============

final menuProductsProvider = FutureProvider<List<Product>>((ref) async {
  return MenuManagementService.getAllProducts();
});

final productsByCategoryProvider = FutureProvider.family<List<Product>, String>(
  (ref, categoryId) async {
    return MenuManagementService.getProductsByCategory(categoryId);
  },
);

final kitchenProductsProvider = FutureProvider<List<Product>>((ref) async {
  return MenuManagementService.getProductsByPreparationArea(
    PreparationArea.kitchen,
  );
});

final barProductsProvider = FutureProvider<List<Product>>((ref) async {
  return MenuManagementService.getProductsByPreparationArea(
    PreparationArea.bar,
  );
});

// ============ Menu Structure Providers ============

final menuStructureProvider = FutureProvider.autoDispose<Map<MenuCategory, List<Product>>>((
  ref,
) async {
  return MenuManagementService.getMenuStructure();
});

final foodMenuStructureProvider =
    FutureProvider.autoDispose<Map<MenuCategory, List<Product>>>((ref) async {
      return MenuManagementService.getMenuStructureByType(CategoryType.food);
    });

final alcoholMenuStructureProvider =
    FutureProvider.autoDispose<Map<MenuCategory, List<Product>>>((ref) async {
      return MenuManagementService.getMenuStructureByType(CategoryType.alcohol);
    });

// ============ Statistics Providers ============

final categoryStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      categoryId,
    ) async {
      return MenuManagementService.getCategoryStats(categoryId);
    });

// ============ State Management Provider ============

final menuManagementControllerProvider =
    StateNotifierProvider<MenuManagementController, MenuManagementState>((ref) {
      return MenuManagementController();
    });

class MenuManagementState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const MenuManagementState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  MenuManagementState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return MenuManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class MenuManagementController extends StateNotifier<MenuManagementState> {
  MenuManagementController() : super(const MenuManagementState());

  // ============ Category Management ============

  Future<bool> createCategory(MenuCategory category) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.createCategory(category);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Category "${category.name}" created successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create category',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(MenuCategory category) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.updateCategory(category);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Category "${category.name}" updated successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update category',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId, String categoryName) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.deleteCategory(categoryId);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Category "$categoryName" deleted successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete category',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ============ Product Management ============

  Future<bool> createProduct(Product product) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.createProduct(product);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product "${product.name}" created successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create product',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.updateProduct(product);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product "${product.name}" updated successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update product',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String productName) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.deleteProduct(productId);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product "$productName" deleted successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete product',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> initializeDefaultCategories() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final success = await MenuManagementService.initializeDefaultCategories();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Default categories created successfully',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Categories already exist',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
