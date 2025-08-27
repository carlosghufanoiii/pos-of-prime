import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'network_service.dart';

class LanApiService {
  static LanApiService? _instance;
  static LanApiService get instance => _instance ??= LanApiService._();
  LanApiService._();

  late Dio _dio;
  String? _authToken;
  String? _baseUrl;

  /// Initialize the service
  Future<void> initialize() async {
    final networkService = NetworkService.instance;
    _baseUrl = networkService.localServerUrl;

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        Logger.error(
          '🔥 LAN API Error: ${error.response?.statusCode} ${error.message}',
          error: error,
          tag: 'LanApiService',
        );
        handler.next(error);
      },
    ));

    // Load saved auth token
    await _loadAuthToken();

    Logger.info('✅ LAN API Service initialized', tag: 'LanApiService');
  }

  /// Update base URL when network changes
  void updateBaseUrl(String? newBaseUrl) {
    if (_baseUrl != newBaseUrl) {
      _baseUrl = newBaseUrl;
      _dio.options.baseUrl = newBaseUrl ?? '';
      Logger.info('🔄 Updated LAN API base URL: $newBaseUrl', tag: 'LanApiService');
    }
  }

  /// Check if service is available
  bool get isAvailable => _baseUrl != null && _baseUrl!.isNotEmpty;

  // Authentication Methods

  /// Login with email and password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        _authToken = response.data['token'];
        await _saveAuthToken(_authToken!);
        
        Logger.info('✅ LAN login successful: $email', tag: 'LanApiService');
        return response.data;
      }
    } catch (e) {
      Logger.error('❌ LAN login failed', error: e, tag: 'LanApiService');
      rethrow;
    }
    return null;
  }

  /// Logout
  Future<void> logout() async {
    _authToken = null;
    await _clearAuthToken();
    Logger.info('👋 LAN logout completed', tag: 'LanApiService');
  }

  // User Management Methods

  /// Get current user info
  Future<AppUser?> getCurrentUser() async {
    if (!isAvailable || _authToken == null) return null;

    try {
      final response = await _dio.get('/api/user/me');
      
      if (response.statusCode == 200 && response.data['user'] != null) {
        return AppUser.fromJson(response.data['user']);
      }
    } catch (e) {
      Logger.error('❌ Failed to get current user', error: e, tag: 'LanApiService');
    }
    return null;
  }

  /// Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.get('/api/users');
      
      if (response.statusCode == 200 && response.data['users'] != null) {
        final List<dynamic> usersJson = response.data['users'];
        return usersJson.map((json) => AppUser.fromJson(json)).toList();
      }
    } catch (e) {
      Logger.error('❌ Failed to get users', error: e, tag: 'LanApiService');
      rethrow;
    }
    return [];
  }

  /// Create user (admin only)
  Future<bool> createUser(AppUser user, String password) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.post('/api/users', data: {
        'email': user.email,
        'name': user.name,
        'password': password,
        'role': user.role.name,
      });

      if (response.statusCode == 201) {
        Logger.info('✅ User created: ${user.email}', tag: 'LanApiService');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Failed to create user', error: e, tag: 'LanApiService');
      rethrow;
    }
    return false;
  }

  /// Update user (admin only)
  Future<bool> updateUser(AppUser user) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.put('/api/users/${user.id}', data: {
        'name': user.name,
        'role': user.role.name,
        'isActive': user.isActive,
      });

      if (response.statusCode == 200) {
        Logger.info('✅ User updated: ${user.email}', tag: 'LanApiService');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Failed to update user', error: e, tag: 'LanApiService');
      rethrow;
    }
    return false;
  }

  // Product Management Methods

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.get('/api/products');
      
      if (response.statusCode == 200 && response.data['products'] != null) {
        final List<dynamic> productsJson = response.data['products'];
        return productsJson.map((json) => Product.fromLanJson(json)).toList();
      }
    } catch (e) {
      Logger.error('❌ Failed to get products', error: e, tag: 'LanApiService');
      rethrow;
    }
    return [];
  }

  /// Create product (admin only)
  Future<bool> createProduct(Product product) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.post('/api/products', data: {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'category': product.category,
        'isAlcoholic': product.isAlcoholic,
        'stockQuantity': product.stockQuantity,
        'imageUrl': product.imageUrl,
      });

      if (response.statusCode == 201) {
        Logger.info('✅ Product created: ${product.name}', tag: 'LanApiService');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Failed to create product', error: e, tag: 'LanApiService');
      rethrow;
    }
    return false;
  }

  // Order Management Methods

  /// Get orders with optional filters
  Future<List<Order>> getOrders({
    String? status,
    String? waiterId,
  }) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (waiterId != null) queryParams['waiter_id'] = waiterId;

      final response = await _dio.get(
        '/api/orders',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data['orders'] != null) {
        final List<dynamic> ordersJson = response.data['orders'];
        return ordersJson.map((json) => Order.fromLanJson(json)).toList();
      }
    } catch (e) {
      Logger.error('❌ Failed to get orders', error: e, tag: 'LanApiService');
      rethrow;
    }
    return [];
  }

  /// Create order
  Future<String?> createOrder(Order order) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.post('/api/orders', data: {
        'tableNumber': order.tableNumber,
        'customerName': order.customerName,
        'notes': order.notes,
        'items': order.items.map((item) => {
          'productId': item.product.id,
          'productName': item.product.name,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
        }).toList(),
      });

      if (response.statusCode == 201 && response.data['order'] != null) {
        final orderData = response.data['order'];
        Logger.info('✅ Order created: ${orderData['orderNumber']}', tag: 'LanApiService');
        return orderData['orderNumber'];
      }
    } catch (e) {
      Logger.error('❌ Failed to create order', error: e, tag: 'LanApiService');
      rethrow;
    }
    return null;
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status, String? userId) async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.put('/api/orders/$orderId/status', data: {
        'status': status.name,
        if (userId != null) 'userId': userId,
      });

      if (response.statusCode == 200) {
        Logger.info('✅ Order status updated: $orderId -> ${status.name}', tag: 'LanApiService');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Failed to update order status', error: e, tag: 'LanApiService');
      rethrow;
    }
    return false;
  }

  // Statistics Methods

  /// Get system statistics
  Future<Map<String, dynamic>?> getStats() async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.get('/api/stats');
      
      if (response.statusCode == 200 && response.data['stats'] != null) {
        return response.data['stats'];
      }
    } catch (e) {
      Logger.error('❌ Failed to get stats', error: e, tag: 'LanApiService');
      rethrow;
    }
    return null;
  }

  // Server Information Methods

  /// Get server info
  Future<Map<String, dynamic>?> getServerInfo() async {
    if (!isAvailable) return null;

    try {
      final response = await _dio.get('/api/server/info');
      
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      Logger.debug('Server info not available', tag: 'LanApiService');
    }
    return null;
  }

  /// Health check
  Future<bool> healthCheck() async {
    if (!isAvailable) return false;

    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200 && 
             response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  // Cloud Sync Methods

  /// Trigger cloud sync (admin only)
  Future<bool> syncWithCloud() async {
    if (!isAvailable) throw Exception('Local server not available');

    try {
      final response = await _dio.post('/api/sync/cloud');
      
      if (response.statusCode == 200) {
        Logger.info('✅ Cloud sync initiated', tag: 'LanApiService');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Failed to sync with cloud', error: e, tag: 'LanApiService');
      rethrow;
    }
    return false;
  }

  // Private Methods

  /// Save auth token to local storage
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lan_auth_token', token);
    Logger.debug('💾 Saved LAN auth token', tag: 'LanApiService');
  }

  /// Load auth token from local storage
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('lan_auth_token');
    if (_authToken != null) {
      Logger.debug('📂 Loaded LAN auth token', tag: 'LanApiService');
    }
  }

  /// Clear auth token from local storage
  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lan_auth_token');
    Logger.debug('🗑️ Cleared LAN auth token', tag: 'LanApiService');
  }
}

/// Extension to convert LAN API responses to app models
extension ProductLanExtension on Product {
  static Product fromLanJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'] ?? 'SKU-${json['id']}',
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      isAlcoholic: json['is_alcoholic'] == 1 || json['is_alcoholic'] == true,
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}

extension OrderLanExtension on Order {
  static Order fromLanJson(Map<String, dynamic> json) {
    final List<OrderItem> items = [];
    if (json['items'] != null) {
      for (final itemJson in json['items']) {
        // Create a product from the order item data
        final product = Product(
          id: itemJson['productId'] ?? '',
          name: itemJson['productName'] ?? '',
          sku: itemJson['productSku'] ?? 'SKU-${itemJson['productId']}',
          price: itemJson['unitPrice']?.toDouble() ?? 0.0,
          category: itemJson['productCategory'] ?? '', // Not available from order item
          isAlcoholic: itemJson['isAlcoholic'] == 1 || itemJson['isAlcoholic'] == true,
          stockQuantity: itemJson['stockQuantity'] ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        items.add(OrderItem(
          id: itemJson['id'] ?? '',
          product: product,
          quantity: itemJson['quantity'] ?? 1,
          unitPrice: itemJson['unitPrice']?.toDouble() ?? 0.0,
          totalPrice: itemJson['totalPrice']?.toDouble() ?? 0.0,
        ));
      }
    }

    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      waiterId: json['waiter_id'] ?? '',
      waiterName: json['waiter_name'] ?? '',
      cashierId: json['cashier_id'],
      tableNumber: json['table_number'],
      customerName: json['customer_name'],
      items: items,
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pendingApproval,
      ),
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      readyAt: json['ready_at'] != null ? DateTime.parse(json['ready_at']) : null,
      servedAt: json['served_at'] != null ? DateTime.parse(json['served_at']) : null,
    );
  }
}