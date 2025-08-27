import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'network_service.dart';
import 'local_database_service.dart';
import 'lan_api_service.dart';
import 'firebase_database_service.dart';
import 'sync_service.dart';

/// Central data service that manages all data operations
/// Automatically selects the best data source based on network connectivity
class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();
  DataService._();

  final NetworkService _networkService = NetworkService.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final LanApiService _lanApi = LanApiService.instance;
  final FirebaseDatabaseService _firebaseDb = FirebaseDatabaseService();
  final SyncService _syncService = SyncService.instance;

  bool _isInitialized = false;

  /// Initialize the data service
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('🔧 Initializing Data Service', tag: 'DataService');

    // Initialize all services
    await _networkService.initialize();
    await _localDb.database; // Initialize local database
    await _lanApi.initialize();
    await _syncService.initialize();

    // Listen to network changes to update API base URLs
    _networkService.localServerStream.listen((serverUrl) {
      _lanApi.updateBaseUrl(serverUrl);
    });

    _isInitialized = true;
    Logger.info('✅ Data Service initialized', tag: 'DataService');
  }

  /// Get the best available data source for reads
  DataSource _getReadDataSource() {
    final networkStatus = _networkService.currentStatus;
    
    switch (networkStatus) {
      case NetworkStatus.full:
        // Prefer local server, fallback to cloud
        return _networkService.isConnectedToLocalServer 
            ? DataSource.lan 
            : DataSource.cloud;
      case NetworkStatus.wifiOnly:
        // Only local server available
        return _networkService.isConnectedToLocalServer 
            ? DataSource.lan 
            : DataSource.local;
      case NetworkStatus.internetOnly:
        // Only cloud available
        return DataSource.cloud;
      case NetworkStatus.offline:
        // Only local database
        return DataSource.local;
    }
  }

  /// Get the best available data source for writes
  DataSource _getWriteDataSource() {
    final networkStatus = _networkService.currentStatus;
    
    switch (networkStatus) {
      case NetworkStatus.full:
      case NetworkStatus.wifiOnly:
        // Prefer local server for faster writes
        return _networkService.isConnectedToLocalServer 
            ? DataSource.lan 
            : DataSource.local;
      case NetworkStatus.internetOnly:
        // Use cloud if available, otherwise local with sync
        return DataSource.cloud;
      case NetworkStatus.offline:
        // Always local, will sync later
        return DataSource.local;
    }
  }

  // Authentication Methods

  /// Login user
  Future<AppUser?> login(String email, String password) async {
    Logger.info('🔐 Attempting login: $email', tag: 'DataService');

    AppUser? user;

    try {
      // Try LAN server first if available
      if (_networkService.isConnectedToLocalServer) {
        try {
          final result = await _lanApi.login(email, password);
          if (result != null && result['user'] != null) {
            user = AppUser.fromJson(result['user']);
            await _localDb.saveUser(user); // Cache locally
            Logger.info('✅ LAN login successful', tag: 'DataService');
            return user;
          }
        } catch (e) {
          Logger.warning('⚠️ LAN login failed, trying Firebase', tag: 'DataService');
        }
      }

      // Try Firebase if internet is available
      if (_networkService.hasInternetAccess) {
        try {
          user = await _firebaseDb.signInWithEmailAndPassword(email, password);
          if (user != null) {
            await _localDb.saveUser(user); // Cache locally
            Logger.info('✅ Firebase login successful', tag: 'DataService');
            return user;
          }
        } catch (e) {
          Logger.warning('⚠️ Firebase login failed', tag: 'DataService');
        }
      }

      // Try local cache (for offline scenarios)
      user = await _localDb.getUserByEmail(email);
      if (user != null) {
        Logger.info('✅ Offline login from cache', tag: 'DataService');
        return user;
      }

      Logger.error('❌ All login methods failed', tag: 'DataService');
      return null;

    } catch (e) {
      Logger.error('❌ Login error', error: e, tag: 'DataService');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _lanApi.logout();
    await _firebaseDb.signOut();
    Logger.info('👋 User logged out', tag: 'DataService');
  }

  // Product Methods

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    final source = _getReadDataSource();
    
    try {
      List<Product> products = [];

      switch (source) {
        case DataSource.lan:
          products = await _lanApi.getAllProducts();
          // Cache to local database
          await _localDb.saveProducts(products);
          break;
          
        case DataSource.cloud:
          products = await _firebaseDb.getAllProducts();
          // Cache to local database
          await _localDb.saveProducts(products);
          break;
          
        case DataSource.local:
          products = await _localDb.getAllProducts();
          break;
      }

      Logger.debug('📦 Loaded ${products.length} products from ${source.name}', tag: 'DataService');
      return products;

    } catch (e) {
      Logger.error('❌ Failed to get products from ${source.name}', error: e, tag: 'DataService');
      
      // Fallback to local database
      if (source != DataSource.local) {
        Logger.info('🔄 Falling back to local database', tag: 'DataService');
        return await _localDb.getAllProducts();
      }
      
      rethrow;
    }
  }

  /// Create product (admin only)
  Future<bool> createProduct(Product product) async {
    final source = _getWriteDataSource();

    try {
      bool success = false;

      switch (source) {
        case DataSource.lan:
          success = await _lanApi.createProduct(product);
          if (success) {
            await _localDb.saveProduct(product); // Cache locally
          }
          break;
          
        case DataSource.cloud:
          success = await _firebaseDb.createProduct(product);
          if (success) {
            await _localDb.saveProduct(product); // Cache locally
          }
          break;
          
        case DataSource.local:
          await _localDb.saveProduct(product, addToSyncQueue: true);
          success = true;
          break;
      }

      Logger.info('✅ Product created: ${product.name} (${source.name})', tag: 'DataService');
      return success;

    } catch (e) {
      Logger.error('❌ Failed to create product', error: e, tag: 'DataService');
      
      // Always save to local as fallback
      await _localDb.saveProduct(product, addToSyncQueue: true);
      Logger.info('💾 Product saved locally for sync', tag: 'DataService');
      return true;
    }
  }

  // Order Methods

  /// Get orders with optional filters
  Future<List<Order>> getOrders({
    OrderStatus? status,
    String? waiterId,
  }) async {
    final source = _getReadDataSource();

    try {
      List<Order> orders = [];

      switch (source) {
        case DataSource.lan:
          orders = await _lanApi.getOrders(
            status: status?.name,
            waiterId: waiterId,
          );
          // Cache to local database
          for (final order in orders) {
            await _localDb.saveOrder(order, addToSyncQueue: false);
          }
          break;
          
        case DataSource.cloud:
          orders = await _firebaseDb.getOrders(
            status: status,
            waiterId: waiterId,
          );
          // Cache to local database
          for (final order in orders) {
            await _localDb.saveOrder(order, addToSyncQueue: false);
          }
          break;
          
        case DataSource.local:
          orders = await _localDb.getOrders(
            status: status,
            waiterId: waiterId,
          );
          break;
      }

      Logger.debug('📋 Loaded ${orders.length} orders from ${source.name}', tag: 'DataService');
      return orders;

    } catch (e) {
      Logger.error('❌ Failed to get orders from ${source.name}', error: e, tag: 'DataService');
      
      // Fallback to local database
      if (source != DataSource.local) {
        Logger.info('🔄 Falling back to local database', tag: 'DataService');
        return await _localDb.getOrders(status: status, waiterId: waiterId);
      }
      
      rethrow;
    }
  }

  /// Create order
  Future<String?> createOrder(Order order) async {
    final source = _getWriteDataSource();

    try {
      String? orderNumber;

      switch (source) {
        case DataSource.lan:
          orderNumber = await _lanApi.createOrder(order);
          if (orderNumber != null) {
            await _localDb.saveOrder(order, addToSyncQueue: false);
          }
          break;
          
        case DataSource.cloud:
          orderNumber = await _firebaseDb.createOrder(order);
          if (orderNumber != null) {
            await _localDb.saveOrder(order, addToSyncQueue: false);
          }
          break;
          
        case DataSource.local:
          await _localDb.saveOrder(order, addToSyncQueue: true);
          orderNumber = order.orderNumber;
          break;
      }

      Logger.info('✅ Order created: $orderNumber (${source.name})', tag: 'DataService');
      return orderNumber;

    } catch (e) {
      Logger.error('❌ Failed to create order', error: e, tag: 'DataService');
      
      // Always save to local as fallback
      await _localDb.saveOrder(order, addToSyncQueue: true);
      Logger.info('💾 Order saved locally for sync', tag: 'DataService');
      return order.orderNumber;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status, {String? cashierId}) async {
    final source = _getWriteDataSource();

    try {
      bool success = false;

      switch (source) {
        case DataSource.lan:
          success = await _lanApi.updateOrderStatus(orderId, status, cashierId);
          if (success) {
            await _localDb.updateOrderStatus(orderId, status, cashierId: cashierId, addToSyncQueue: false);
          }
          break;
          
        case DataSource.cloud:
          success = await _firebaseDb.updateOrderStatus(orderId, status, cashierId);
          if (success) {
            await _localDb.updateOrderStatus(orderId, status, cashierId: cashierId, addToSyncQueue: false);
          }
          break;
          
        case DataSource.local:
          await _localDb.updateOrderStatus(orderId, status, cashierId: cashierId, addToSyncQueue: true);
          success = true;
          break;
      }

      Logger.info('✅ Order status updated: $orderId -> ${status.name} (${source.name})', tag: 'DataService');
      return success;

    } catch (e) {
      Logger.error('❌ Failed to update order status', error: e, tag: 'DataService');
      
      // Always save to local as fallback
      await _localDb.updateOrderStatus(orderId, status, cashierId: cashierId, addToSyncQueue: true);
      Logger.info('💾 Order status saved locally for sync', tag: 'DataService');
      return true;
    }
  }

  // User Management Methods

  /// Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    final source = _getReadDataSource();

    try {
      List<AppUser> users = [];

      switch (source) {
        case DataSource.lan:
          users = await _lanApi.getAllUsers();
          // Cache to local database
          for (final user in users) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.cloud:
          users = await _firebaseDb.getAllUsers();
          // Cache to local database
          for (final user in users) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.local:
          users = await _localDb.getAllUsers();
          break;
      }

      Logger.debug('👥 Loaded ${users.length} users from ${source.name}', tag: 'DataService');
      return users;

    } catch (e) {
      Logger.error('❌ Failed to get users from ${source.name}', error: e, tag: 'DataService');
      
      // Fallback to local database
      if (source != DataSource.local) {
        Logger.info('🔄 Falling back to local database', tag: 'DataService');
        return await _localDb.getAllUsers();
      }
      
      rethrow;
    }
  }

  /// Create user (admin only)
  Future<bool> createUser(AppUser user, String password) async {
    final source = _getWriteDataSource();

    try {
      bool success = false;

      switch (source) {
        case DataSource.lan:
          success = await _lanApi.createUser(user, password);
          if (success) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.cloud:
          success = await _firebaseDb.createUser(user, password: password);
          if (success) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.local:
          await _localDb.saveUser(user, addToSyncQueue: true);
          success = true;
          break;
      }

      Logger.info('✅ User created: ${user.email} (${source.name})', tag: 'DataService');
      return success;

    } catch (e) {
      Logger.error('❌ Failed to create user', error: e, tag: 'DataService');
      
      // Always save to local as fallback
      await _localDb.saveUser(user, addToSyncQueue: true);
      Logger.info('💾 User saved locally for sync', tag: 'DataService');
      return true;
    }
  }

  /// Update user (admin only)
  Future<bool> updateUser(AppUser user) async {
    final source = _getWriteDataSource();

    try {
      bool success = false;

      switch (source) {
        case DataSource.lan:
          success = await _lanApi.updateUser(user);
          if (success) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.cloud:
          success = await _firebaseDb.updateUser(user);
          if (success) {
            await _localDb.saveUser(user);
          }
          break;
          
        case DataSource.local:
          await _localDb.saveUser(user, addToSyncQueue: true);
          success = true;
          break;
      }

      Logger.info('✅ User updated: ${user.email} (${source.name})', tag: 'DataService');
      return success;

    } catch (e) {
      Logger.error('❌ Failed to update user', error: e, tag: 'DataService');
      
      // Always save to local as fallback
      await _localDb.saveUser(user, addToSyncQueue: true);
      Logger.info('💾 User update saved locally for sync', tag: 'DataService');
      return true;
    }
  }

  // Sync Methods

  /// Trigger manual sync
  Future<bool> syncData() async {
    return await _syncService.syncAll();
  }

  /// Force complete resync
  Future<bool> forceResync() async {
    return await _syncService.forceCompleteResync();
  }

  /// Get sync status
  SyncStatus getSyncStatus() {
    return _syncService.status;
  }

  /// Get sync stream
  Stream<SyncStatus> getSyncStatusStream() {
    return _syncService.statusStream;
  }

  // Utility Methods

  /// Get connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      ..._networkService.getConnectionInfo(),
      'preferredReadSource': _getReadDataSource().name,
      'preferredWriteSource': _getWriteDataSource().name,
      'syncStatus': _syncService.status.name,
      'lastSyncTime': _syncService.lastSyncTime?.toIso8601String(),
    };
  }

  /// Check if app is in offline mode
  bool get isOfflineMode => _networkService.currentStatus == NetworkStatus.offline;

  /// Check if local server is available
  bool get hasLocalServer => _networkService.isConnectedToLocalServer;

  /// Check if internet is available
  bool get hasInternet => _networkService.hasInternetAccess;

  /// Get network status description
  String getNetworkStatusDescription() {
    return _networkService.getNetworkStatusDescription();
  }
}

/// Data sources available to the application
enum DataSource {
  local,  // Local SQLite database
  lan,    // Local area network server
  cloud,  // Firebase/Cloud services
}

/// Extension for better names
extension DataSourceExtension on DataSource {
  String get displayName {
    switch (this) {
      case DataSource.local:
        return 'Offline';
      case DataSource.lan:
        return 'Local Server';
      case DataSource.cloud:
        return 'Cloud';
    }
  }

  IconData get icon {
    switch (this) {
      case DataSource.local:
        return Icons.storage;
      case DataSource.lan:
        return Icons.router;
      case DataSource.cloud:
        return Icons.cloud;
    }
  }
}

