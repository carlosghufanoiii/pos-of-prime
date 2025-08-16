import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Client-side Appwrite database service for Prime POS
/// Handles document operations and real-time subscriptions
/// Note: Database/collection setup must be done via Appwrite Console
class AppwriteDatabaseService {
  static Client? _client;
  static Databases? _databases;
  static Realtime? _realtime;
  static bool _initialized = false;

  // Database and collection IDs (must exist in Appwrite Console)
  static const String databaseId = 'prime_pos_db';
  static const String usersCollectionId = 'users';
  static const String productsCollectionId = 'products';
  static const String ordersCollectionId = 'orders';

  /// Initialize Appwrite connection
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _client = Client()
          .setEndpoint('http://localhost/v1')
          .setProject('prime-pos');

      _databases = Databases(_client!);
      _realtime = Realtime(_client!);

      // Check if database and collections exist
      await _checkDatabaseSetup();
      
      _initialized = true;
      print('✅ Appwrite database service initialized');
    } catch (e) {
      print('❌ Failed to initialize Appwrite: $e');
      rethrow;
    }
  }

  /// Check if service is ready
  static bool get isReady => _initialized && _databases != null;

  /// Check if database and collections exist
  static Future<void> _checkDatabaseSetup() async {
    try {
      // Try to list documents to verify collections exist
      await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [],
      );
      print('✅ Database and collections verified');
    } catch (e) {
      print('⚠️ Database/collections not found. Please set up via Appwrite Console: $e');
      // Don't throw - allow app to continue with limited functionality
    }
  }

  // === USER OPERATIONS ===
  
  /// Get all users
  static Future<List<AppUser>> getUsers() async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final result = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
      );
      
      return result.documents.map((doc) => AppUser.fromJson({
        'id': doc.$id,
        'email': doc.data['email'],
        'displayName': doc.data['displayName'],
        'role': doc.data['role'],
        'isActive': doc.data['isActive'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }
  
  /// Create new user
  static Future<AppUser> createUser(AppUser user) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.createDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: ID.unique(),
        data: {
          'email': user.email,
          'displayName': user.displayName,
          'role': user.role.name,
          'isActive': user.isActive,
        },
      );
      
      return AppUser.fromJson({
        'id': doc.$id,
        'email': doc.data['email'],
        'displayName': doc.data['displayName'],
        'role': doc.data['role'],
        'isActive': doc.data['isActive'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user
  static Future<AppUser> updateUser(AppUser user) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: user.id,
        data: {
          'email': user.email,
          'displayName': user.displayName,
          'role': user.role.name,
          'isActive': user.isActive,
        },
      );
      
      return AppUser.fromJson({
        'id': doc.$id,
        'email': doc.data['email'],
        'displayName': doc.data['displayName'],
        'role': doc.data['role'],
        'isActive': doc.data['isActive'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  static Future<void> deleteUser(String userId) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      await _databases!.deleteDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get user by ID
  static Future<AppUser?> getUserById(String userId) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
      
      return AppUser.fromJson({
        'id': doc.$id,
        'email': doc.data['email'],
        'displayName': doc.data['displayName'],
        'role': doc.data['role'],
        'isActive': doc.data['isActive'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to get user by ID: $e');
      return null;
    }
  }

  // === PRODUCT OPERATIONS ===
  
  /// Get all products
  static Future<List<Product>> getProducts() async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final result = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollectionId,
      );
      
      return result.documents.map((doc) => Product.fromJson({
        'id': doc.$id,
        'name': doc.data['name'],
        'sku': doc.data['sku'],
        'price': doc.data['price'],
        'category': doc.data['category'],
        'isAlcoholic': doc.data['isAlcoholic'],
        'isActive': doc.data['isActive'],
        'description': doc.data['description'],
        'stockQuantity': doc.data['stockQuantity'],
        'preparationArea': doc.data['preparationArea'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }
  
  /// Create new product
  static Future<Product> createProduct(Product product) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.createDocument(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        documentId: ID.unique(),
        data: {
          'name': product.name,
          'sku': product.sku,
          'price': product.price,
          'category': product.category,
          'isAlcoholic': product.isAlcoholic,
          'isActive': product.isActive,
          'description': product.description,
          'stockQuantity': product.stockQuantity,
          'preparationArea': product.preparationArea.name,
        },
      );
      
      return Product.fromJson({
        'id': doc.$id,
        'name': doc.data['name'],
        'sku': doc.data['sku'],
        'price': doc.data['price'],
        'category': doc.data['category'],
        'isAlcoholic': doc.data['isAlcoholic'],
        'isActive': doc.data['isActive'],
        'description': doc.data['description'],
        'stockQuantity': doc.data['stockQuantity'],
        'preparationArea': doc.data['preparationArea'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // === ORDER OPERATIONS ===
  
  /// Get all orders
  static Future<List<Order>> getOrders() async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final result = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
      );
      
      return result.documents.map((doc) => Order.fromJson({
        'id': doc.$id,
        'orderNumber': doc.data['orderNumber'],
        'waiterId': doc.data['waiterId'],
        'waiterName': doc.data['waiterName'],
        'tableNumber': doc.data['tableNumber'],
        'customerName': doc.data['customerName'],
        'status': doc.data['status'],
        'subtotal': doc.data['subtotal'],
        'taxAmount': doc.data['taxAmount'],
        'discount': doc.data['discount'],
        'total': doc.data['total'],
        'paymentMethod': doc.data['paymentMethod'],
        'cashierId': doc.data['cashierId'],
        'cashierName': doc.data['cashierName'],
        'notes': doc.data['notes'],
        'items': jsonDecode(doc.data['items']),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }
  
  /// Create new order
  static Future<Order> createOrder(Order order) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.createDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: ID.unique(),
        data: {
          'orderNumber': order.orderNumber,
          'waiterId': order.waiterId,
          'waiterName': order.waiterName,
          'tableNumber': order.tableNumber,
          'customerName': order.customerName,
          'status': order.status.name,
          'subtotal': order.subtotal,
          'taxAmount': order.taxAmount,
          'discount': order.discount,
          'total': order.total,
          'paymentMethod': order.paymentMethod?.name,
          'cashierId': order.cashierId,
          'cashierName': order.cashierName,
          'notes': order.notes,
          'items': jsonEncode(order.items.map((item) => item.toJson()).toList()),
        },
      );
      
      return order.copyWith(id: doc.$id);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }
  
  /// Update order
  static Future<Order> updateOrder(Order order) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final doc = await _databases!.updateDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: order.id,
        data: {
          'status': order.status.name,
          'paymentMethod': order.paymentMethod?.name,
          'cashierId': order.cashierId,
          'cashierName': order.cashierName,
          'notes': order.notes,
          'items': jsonEncode(order.items.map((item) => item.toJson()).toList()),
        },
      );
      
      return order;
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }
  
  /// Get orders by status
  static Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    if (!isReady) throw Exception('Appwrite not initialized');
    
    try {
      final result = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('status', status.name),
        ],
      );
      
      return result.documents.map((doc) => Order.fromJson({
        'id': doc.$id,
        'orderNumber': doc.data['orderNumber'],
        'waiterId': doc.data['waiterId'],
        'waiterName': doc.data['waiterName'],
        'tableNumber': doc.data['tableNumber'],
        'customerName': doc.data['customerName'],
        'status': doc.data['status'],
        'subtotal': doc.data['subtotal'],
        'taxAmount': doc.data['taxAmount'],
        'discount': doc.data['discount'],
        'total': doc.data['total'],
        'paymentMethod': doc.data['paymentMethod'],
        'cashierId': doc.data['cashierId'],
        'cashierName': doc.data['cashierName'],
        'notes': doc.data['notes'],
        'items': jsonDecode(doc.data['items']),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  /// Real-time subscriptions
  static StreamSubscription<RealtimeMessage>? subscribeToOrders(
    Function(RealtimeMessage) callback
  ) {
    if (!isReady) return null;
    
    try {
      return _realtime!
          .subscribe(['databases.$databaseId.collections.$ordersCollectionId.documents'])
          .stream
          .listen(callback);
    } catch (e) {
      print('❌ Failed to subscribe to orders: $e');
      return null;
    }
  }

  /// Health check
  static Future<bool> checkHealth() async {
    if (!isReady) return false;
    
    try {
      await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [],
      );
      return true;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  // Getters for external access
  static Databases? get databases => _databases;
  static Realtime? get realtime => _realtime;
}