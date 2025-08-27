import 'package:prime_pos/shared/utils/logger.dart';
import '../models/menu_category.dart';
import '../services/firebase_database_service.dart';

class MenuCategoryRepository {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  Future<List<MenuCategory>> getAllCategories() async {
    try {
      return await _dbService.getAllMenuCategories();
    } catch (e) {
      Logger.error(
        'Error getting menu categories',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return [];
    }
  }

  Future<List<MenuCategory>> getCategoriesByType(CategoryType type) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.where((cat) => cat.type == type).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      Logger.error(
        'Error getting categories by type',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return [];
    }
  }

  Future<MenuCategory?> getCategoryById(String categoryId) async {
    try {
      return await _dbService.getMenuCategory(categoryId);
    } catch (e) {
      Logger.error(
        'Error getting category by ID',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return null;
    }
  }

  Future<bool> createCategory(MenuCategory category) async {
    try {
      await _dbService.createMenuCategory(category);
      return true;
    } catch (e) {
      Logger.error(
        'Error creating category',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return false;
    }
  }

  Future<bool> updateCategory(MenuCategory category) async {
    try {
      await _dbService.updateMenuCategory(category);
      return true;
    } catch (e) {
      Logger.error(
        'Error updating category',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _dbService.deleteMenuCategory(categoryId);
      return true;
    } catch (e) {
      Logger.error(
        'Error deleting category',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return false;
    }
  }

  Future<bool> reorderCategories(List<MenuCategory> categories) async {
    try {
      for (int i = 0; i < categories.length; i++) {
        final updatedCategory = categories[i].copyWith(
          sortOrder: i + 1,
          updatedAt: DateTime.now(),
        );
        await updateCategory(updatedCategory);
      }
      return true;
    } catch (e) {
      Logger.error(
        'Error reordering categories',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return false;
    }
  }

  Future<bool> initializeDefaultCategories() async {
    try {
      final existingCategories = await getAllCategories();
      if (existingCategories.isEmpty) {
        final defaultCategories = DefaultMenuCategories.allCategories;
        for (final category in defaultCategories) {
          await createCategory(category);
        }
        return true;
      }
      return false; // Categories already exist
    } catch (e) {
      Logger.error(
        'Error initializing default categories',
        error: e,
        tag: 'MenuCategoryRepository',
      );
      return false;
    }
  }

  Stream<List<MenuCategory>> getCategoriesStream() {
    return _dbService.getMenuCategoriesStream();
  }
}
