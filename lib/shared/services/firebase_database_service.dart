import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../constants/firebase_constants.dart';
import '../models/app_user.dart';
import '../models/product.dart';
import '../models/order.dart' as app_order;
import '../models/menu_category.dart';
import 'firebase_service.dart';

class FirebaseDatabaseService {
  static FirebaseFirestore get _firestore => FirebaseService.firestore;

  // Users Collection Methods
  Future<void> createUser(AppUser user) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.USERS_COLLECTION)
        .doc(user.id)
        .set(user.toJson());
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      await FirebaseService.ensureInitialized();
      final doc = await _firestore
          .collection(FirebaseConstants.USERS_COLLECTION)
          .doc(userId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      Logger.error(
        'Error getting user',
        error: e,
        tag: 'FirebaseDatabaseService',
      );
      // Try from cache if server fails
      try {
        final doc = await _firestore
            .collection(FirebaseConstants.USERS_COLLECTION)
            .doc(userId)
            .get(const GetOptions(source: Source.cache));

        if (doc.exists && doc.data() != null) {
          return AppUser.fromJson(doc.data()!);
        }
      } catch (cacheError) {
        Logger.error(
          'Cache error',
          error: cacheError,
          tag: 'FirebaseDatabaseService',
        );
      }
      return null;
    }
  }

  Future<void> updateUser(AppUser user) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.USERS_COLLECTION)
        .doc(user.id)
        .update(user.toJson());
  }

  Future<void> deleteUser(String userId) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.USERS_COLLECTION)
        .doc(userId)
        .delete();
  }

  Future<List<AppUser>> getAllUsers() async {
    await FirebaseService.ensureInitialized();
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.USERS_COLLECTION)
        .get();

    return querySnapshot.docs
        .map((doc) => AppUser.fromJson(doc.data()))
        .toList();
  }

  Stream<List<AppUser>> getUsersStream() {
    return _firestore
        .collection(FirebaseConstants.USERS_COLLECTION)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList(),
        );
  }

  // Products Collection Methods
  Future<void> createProduct(Product product) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .doc(product.id)
        .set(product.toJson());
  }

  Future<Product?> getProduct(String productId) async {
    await FirebaseService.ensureInitialized();
    final doc = await _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .doc(productId)
        .get();

    if (doc.exists) {
      return Product.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> updateProduct(Product product) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .doc(product.id)
        .update(product.toJson());
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .doc(productId)
        .delete();
  }

  Future<List<Product>> getAllProducts() async {
    await FirebaseService.ensureInitialized();
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .where('isActive', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection(FirebaseConstants.PRODUCTS_COLLECTION)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList(),
        );
  }

  // Orders Collection Methods
  Future<void> createOrder(app_order.Order order) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .doc(order.id)
        .set(order.toJson());
  }

  Future<app_order.Order?> getOrder(String orderId) async {
    await FirebaseService.ensureInitialized();
    final doc = await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .doc(orderId)
        .get();

    if (doc.exists) {
      return app_order.Order.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> updateOrder(app_order.Order order) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .doc(order.id)
        .update(order.toJson());
  }

  Future<void> deleteOrder(String orderId) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .doc(orderId)
        .delete();
  }

  Future<List<app_order.Order>> getAllOrders() async {
    await FirebaseService.ensureInitialized();
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => app_order.Order.fromJson(doc.data()))
        .toList();
  }

  Future<List<app_order.Order>> getOrdersByStatus(String status) async {
    await FirebaseService.ensureInitialized();
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => app_order.Order.fromJson(doc.data()))
        .toList();
  }

  Stream<List<app_order.Order>> getOrdersStream() {
    return _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => app_order.Order.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<app_order.Order>> getOrdersByStatusStream(String status) {
    return _firestore
        .collection(FirebaseConstants.ORDERS_COLLECTION)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => app_order.Order.fromJson(doc.data()))
              .toList(),
        );
  }

  // Analytics Methods
  Future<void> logAnalyticsEvent(Map<String, dynamic> eventData) async {
    await FirebaseService.ensureInitialized();
    await _firestore.collection('analytics').add({
      ...eventData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Batch Operations
  Future<void> updateInventoryBatch(List<Product> products) async {
    await FirebaseService.ensureInitialized();
    final batch = _firestore.batch();

    for (final product in products) {
      final docRef = _firestore
          .collection(FirebaseConstants.PRODUCTS_COLLECTION)
          .doc(product.id);
      batch.update(docRef, product.toJson());
    }

    await batch.commit();
  }

  // Menu Categories Collection Methods
  Future<void> createMenuCategory(MenuCategory category) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection('menu_categories')
        .doc(category.id)
        .set(category.toJson());
  }

  Future<MenuCategory?> getMenuCategory(String categoryId) async {
    try {
      await FirebaseService.ensureInitialized();
      final doc = await _firestore
          .collection('menu_categories')
          .doc(categoryId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        return MenuCategory.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      Logger.error(
        'Error getting menu category',
        error: e,
        tag: 'FirebaseDatabaseService',
      );
      return null;
    }
  }

  Future<void> updateMenuCategory(MenuCategory category) async {
    await FirebaseService.ensureInitialized();
    await _firestore
        .collection('menu_categories')
        .doc(category.id)
        .update(category.toJson());
  }

  Future<void> deleteMenuCategory(String categoryId) async {
    await FirebaseService.ensureInitialized();
    await _firestore.collection('menu_categories').doc(categoryId).delete();
  }

  Future<List<MenuCategory>> getAllMenuCategories() async {
    try {
      await FirebaseService.ensureInitialized();
      final snapshot = await _firestore
          .collection('menu_categories')
          .orderBy('sortOrder')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => MenuCategory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      Logger.error(
        'Error getting all menu categories',
        error: e,
        tag: 'FirebaseDatabaseService',
      );
      return [];
    }
  }

  Stream<List<MenuCategory>> getMenuCategoriesStream() {
    return _firestore
        .collection('menu_categories')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().isNotEmpty)
              .map((doc) => MenuCategory.fromJson(doc.data()))
              .toList(),
        );
  }
}
