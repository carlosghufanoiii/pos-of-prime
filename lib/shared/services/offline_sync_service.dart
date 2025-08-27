import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../models/order.dart';
import '../models/app_user.dart';
import '../models/product.dart';

class OfflineSyncService {
  static const String _ordersBoxName = 'offline_orders';
  static const String _usersBoxName = 'offline_users';
  static const String _productsBoxName = 'offline_products';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _dbName = 'prime_pos_offline.db';
  static const int _dbVersion = 1;

  static Database? _database;
  static Box<Map>? _ordersBox;
  static Box<Map>? _usersBox;
  static Box<Map>? _productsBox;
  static Box<Map>? _syncQueueBox;

  /// Initialize offline storage
  static Future<void> initialize() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open Hive boxes
      _ordersBox = await Hive.openBox<Map>(_ordersBoxName);
      _usersBox = await Hive.openBox<Map>(_usersBoxName);
      _productsBox = await Hive.openBox<Map>(_productsBoxName);
      _syncQueueBox = await Hive.openBox<Map>(_syncQueueBoxName);

      // Initialize SQLite database
      await _initializeDatabase();

      Logger.info(
        'OfflineSyncService initialized successfully',
        tag: 'OfflineSyncService',
      );
    } catch (e) {
      Logger.error(
        'Failed to initialize OfflineSyncService',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to initialize offline storage: $e');
    }
  }

  /// Initialize SQLite database
  static Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  static Future<void> _createTables(Database db, int version) async {
    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        customer_name TEXT,
        table_number INTEGER,
        waiter_name TEXT NOT NULL,
        status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        served_at TEXT,
        prep_started_at TEXT,
        ready_at TEXT,
        synced INTEGER DEFAULT 0,
        items TEXT NOT NULL
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        employee_id TEXT,
        phone_number TEXT,
        address TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        image_url TEXT,
        is_available INTEGER NOT NULL,
        preparation_area TEXT NOT NULL,
        is_alcoholic INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    Logger.info(
      'Database tables created successfully',
      tag: 'OfflineSyncService',
    );
  }

  /// Upgrade database schema
  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database migrations here
    Logger.info(
      'Upgrading database from version $oldVersion to $newVersion',
      tag: 'OfflineSyncService',
    );
  }

  /// Check network connectivity
  static Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Save order offline
  static Future<void> saveOrderOffline(Order order) async {
    try {
      // Save to Hive
      await _ordersBox!.put(order.id, order.toJson());

      // Save to SQLite
      await _database!.insert('orders', {
        'id': order.id,
        'order_number': order.orderNumber,
        'customer_name': order.customerName,
        'table_number': order.tableNumber,
        'waiter_name': order.waiterName,
        'status': order.status.name,
        'subtotal': order.subtotal,
        'tax': order.taxAmount,
        'total': order.total,
        'payment_method': order.paymentMethod?.name,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': order.updatedAt.toIso8601String(),
        'served_at': order.servedAt?.toIso8601String(),
        'prep_started_at': order.prepStartedAt?.toIso8601String(),
        'ready_at': order.readyAt?.toIso8601String(),
        'synced': 0,
        'items': jsonEncode(order.items.map((item) => item.toJson()).toList()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Add to sync queue
      await _addToSyncQueue('order', order.id, 'create', order.toJson());

      Logger.info(
        'Order ${order.orderNumber} saved offline',
        tag: 'OfflineSyncService',
      );
    } catch (e) {
      Logger.error(
        'Failed to save order offline',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to save order offline: $e');
    }
  }

  /// Update order offline
  static Future<void> updateOrderOffline(Order order) async {
    try {
      // Update in Hive
      await _ordersBox!.put(order.id, order.toJson());

      // Update in SQLite
      await _database!.update(
        'orders',
        {
          'order_number': order.orderNumber,
          'customer_name': order.customerName,
          'table_number': order.tableNumber,
          'waiter_name': order.waiterName,
          'status': order.status.name,
          'subtotal': order.subtotal,
          'tax': order.taxAmount,
          'total': order.total,
          'payment_method': order.paymentMethod?.name,
          'updated_at': order.updatedAt.toIso8601String(),
          'served_at': order.servedAt?.toIso8601String(),
          'prep_started_at': order.prepStartedAt?.toIso8601String(),
          'ready_at': order.readyAt?.toIso8601String(),
          'items': jsonEncode(
            order.items.map((item) => item.toJson()).toList(),
          ),
        },
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Add to sync queue
      await _addToSyncQueue('order', order.id, 'update', order.toJson());

      Logger.info(
        'Order ${order.orderNumber} updated offline',
        tag: 'OfflineSyncService',
      );
    } catch (e) {
      Logger.error(
        'Failed to update order offline',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to update order offline: $e');
    }
  }

  /// Get offline orders
  static Future<List<Order>> getOfflineOrders() async {
    try {
      final results = await _database!.query(
        'orders',
        orderBy: 'created_at DESC',
      );

      final orders = <Order>[];
      for (final row in results) {
        try {
          final itemsJson = jsonDecode(row['items'] as String) as List;
          final items = itemsJson
              .map((item) => OrderItem.fromJson(item))
              .toList();

          final order = Order.fromJson(
            {...row, 'items': items.map((item) => item.toJson()).toList()}
                as Map<String, dynamic>,
          );

          orders.add(order);
        } catch (e) {
          Logger.warning(
            'Failed to parse offline order',
            error: e,
            tag: 'OfflineSyncService',
          );
        }
      }

      return orders;
    } catch (e) {
      Logger.error(
        'Failed to get offline orders',
        error: e,
        tag: 'OfflineSyncService',
      );
      return [];
    }
  }

  /// Save user offline
  static Future<void> saveUserOffline(AppUser user) async {
    try {
      // Save to Hive
      await _usersBox!.put(user.id, user.toJson());

      // Save to SQLite
      await _database!.insert('users', {
        'id': user.id,
        'email': user.email,
        'display_name': user.name,
        'role': user.role.name,
        'is_active': user.isActive ? 1 : 0,
        'created_at': user.createdAt.toIso8601String(),
        'last_login_at': user.lastLoginAt?.toIso8601String(),
        'employee_id': user.employeeId,
        'phone_number': user.phoneNumber,
        'address': user.address,
        'synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Add to sync queue
      await _addToSyncQueue('user', user.id, 'create', user.toJson());

      Logger.info('User ${user.name} saved offline', tag: 'OfflineSyncService');
    } catch (e) {
      Logger.error(
        'Failed to save user offline',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to save user offline: $e');
    }
  }

  /// Get offline users
  static Future<List<AppUser>> getOfflineUsers() async {
    try {
      final results = await _database!.query(
        'users',
        orderBy: 'display_name ASC',
      );

      final users = <AppUser>[];
      for (final row in results) {
        try {
          final user = AppUser.fromJson(row as Map<String, dynamic>);
          users.add(user);
        } catch (e) {
          Logger.warning(
            'Failed to parse offline user',
            error: e,
            tag: 'OfflineSyncService',
          );
        }
      }

      return users;
    } catch (e) {
      Logger.error(
        'Failed to get offline users',
        error: e,
        tag: 'OfflineSyncService',
      );
      return [];
    }
  }

  /// Save product offline
  static Future<void> saveProductOffline(Product product) async {
    try {
      // Save to Hive
      await _productsBox!.put(product.id, product.toJson());

      // Save to SQLite
      await _database!.insert('products', {
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'description': product.description,
        'image_url': product.imageUrl,
        'is_available': product.isActive ? 1 : 0,
        'preparation_area': product.preparationArea.name,
        'is_alcoholic': product.isAlcoholic ? 1 : 0,
        'synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Add to sync queue
      await _addToSyncQueue('product', product.id, 'create', product.toJson());

      Logger.info(
        'Product ${product.name} saved offline',
        tag: 'OfflineSyncService',
      );
    } catch (e) {
      Logger.error(
        'Failed to save product offline',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to save product offline: $e');
    }
  }

  /// Get offline products
  static Future<List<Product>> getOfflineProducts() async {
    try {
      final results = await _database!.query('products', orderBy: 'name ASC');

      final products = <Product>[];
      for (final row in results) {
        try {
          final product = Product.fromJson(row as Map<String, dynamic>);
          products.add(product);
        } catch (e) {
          Logger.warning(
            'Failed to parse offline product',
            error: e,
            tag: 'OfflineSyncService',
          );
        }
      }

      return products;
    } catch (e) {
      Logger.error(
        'Failed to get offline products',
        error: e,
        tag: 'OfflineSyncService',
      );
      return [];
    }
  }

  /// Add item to sync queue
  static Future<void> _addToSyncQueue(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      await _database!.insert('sync_queue', {
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'data': jsonEncode(data),
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    } catch (e) {
      Logger.error(
        'Failed to add to sync queue',
        error: e,
        tag: 'OfflineSyncService',
      );
    }
  }

  /// Get pending sync items
  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final results = await _database!.query(
        'sync_queue',
        orderBy: 'created_at ASC',
      );

      return results;
    } catch (e) {
      Logger.error(
        'Failed to get pending sync items',
        error: e,
        tag: 'OfflineSyncService',
      );
      return [];
    }
  }

  /// Mark item as synced
  static Future<void> markItemSynced(
    int syncQueueId,
    String entityType,
    String entityId,
  ) async {
    try {
      // Remove from sync queue
      await _database!.delete(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [syncQueueId],
      );

      // Mark entity as synced
      String tableName;
      switch (entityType) {
        case 'order':
          tableName = 'orders';
          break;
        case 'user':
          tableName = 'users';
          break;
        case 'product':
          tableName = 'products';
          break;
        default:
          return;
      }

      await _database!.update(
        tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [entityId],
      );

      Logger.debug(
        'Marked $entityType $entityId as synced',
        tag: 'OfflineSyncService',
      );
    } catch (e) {
      Logger.error(
        'Failed to mark item as synced',
        error: e,
        tag: 'OfflineSyncService',
      );
    }
  }

  /// Increment retry count for sync item
  static Future<void> incrementRetryCount(int syncQueueId) async {
    try {
      await _database!.rawUpdate(
        'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
        [syncQueueId],
      );
    } catch (e) {
      Logger.error(
        'Failed to increment retry count',
        error: e,
        tag: 'OfflineSyncService',
      );
    }
  }

  /// Clear all offline data
  static Future<void> clearOfflineData() async {
    try {
      // Clear Hive boxes
      await _ordersBox?.clear();
      await _usersBox?.clear();
      await _productsBox?.clear();
      await _syncQueueBox?.clear();

      // Clear SQLite tables
      await _database?.delete('orders');
      await _database?.delete('users');
      await _database?.delete('products');
      await _database?.delete('sync_queue');

      Logger.info('All offline data cleared', tag: 'OfflineSyncService');
    } catch (e) {
      Logger.error(
        'Failed to clear offline data',
        error: e,
        tag: 'OfflineSyncService',
      );
      throw Exception('Failed to clear offline data: $e');
    }
  }

  /// Get offline storage statistics
  static Future<Map<String, int>> getOfflineStats() async {
    try {
      final ordersCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE synced = 0',
      );
      final usersCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE synced = 0',
      );
      final productsCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE synced = 0',
      );
      final pendingSyncCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue',
      );

      return {
        'unsyncedOrders': ordersCount.first['count'] as int,
        'unsyncedUsers': usersCount.first['count'] as int,
        'unsyncedProducts': productsCount.first['count'] as int,
        'pendingSyncItems': pendingSyncCount.first['count'] as int,
      };
    } catch (e) {
      Logger.error(
        'Failed to get offline stats',
        error: e,
        tag: 'OfflineSyncService',
      );
      return {
        'unsyncedOrders': 0,
        'unsyncedUsers': 0,
        'unsyncedProducts': 0,
        'pendingSyncItems': 0,
      };
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      await _ordersBox?.close();
      await _usersBox?.close();
      await _productsBox?.close();
      await _syncQueueBox?.close();
      await _database?.close();

      Logger.info('OfflineSyncService disposed', tag: 'OfflineSyncService');
    } catch (e) {
      Logger.error(
        'Failed to dispose OfflineSyncService',
        error: e,
        tag: 'OfflineSyncService',
      );
    }
  }
}
