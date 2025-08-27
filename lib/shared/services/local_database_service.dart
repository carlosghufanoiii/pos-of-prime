import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';

class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  static LocalDatabaseService get instance => _instance ??= LocalDatabaseService._();
  LocalDatabaseService._();

  static Database? _database;
  final _uuid = const Uuid();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prime_pos_local.db');

    Logger.info('📂 Initializing local database: $path', tag: 'LocalDatabase');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    Logger.info('🔨 Creating local database tables', tag: 'LocalDatabase');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_sync TEXT,
        sync_status TEXT DEFAULT 'synced' -- 'synced', 'pending', 'failed'
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        is_alcoholic INTEGER NOT NULL DEFAULT 0,
        is_in_stock INTEGER NOT NULL DEFAULT 1,
        stock_quantity INTEGER DEFAULT 0,
        image_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        last_sync TEXT,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT UNIQUE NOT NULL,
        waiter_id TEXT NOT NULL,
        waiter_name TEXT NOT NULL,
        cashier_id TEXT,
        table_number TEXT,
        customer_name TEXT,
        status TEXT NOT NULL DEFAULT 'pending_approval',
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        approved_at TEXT,
        ready_at TEXT,
        served_at TEXT,
        updated_at TEXT NOT NULL,
        last_sync TEXT,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // Order Items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Sync Queue table for tracking changes
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL, -- 'insert', 'update', 'delete'
        data TEXT, -- JSON string
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        sync_attempts INTEGER DEFAULT 0,
        last_sync_attempt TEXT
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    Logger.info('✅ Local database tables created', tag: 'LocalDatabase');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    Logger.info('⬆️ Upgrading database from v$oldVersion to v$newVersion', tag: 'LocalDatabase');
    // Add upgrade logic here when needed
  }

  // User Management Methods

  /// Save user locally
  Future<void> saveUser(AppUser user, {bool addToSyncQueue = false}) async {
    final db = await database;
    
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role.name,
        'is_active': user.isActive ? 1 : 0,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
        'sync_status': addToSyncQueue ? 'pending' : 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (addToSyncQueue) {
      await _addToSyncQueue('users', user.id, 'insert', user.toJson());
    }

    Logger.debug('💾 User saved locally: ${user.email}', tag: 'LocalDatabase');
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return AppUser.fromLocalJson(results.first);
    }
    return null;
  }

  /// Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      return AppUser.fromLocalJson(results.first);
    }
    return null;
  }

  /// Get all users
  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    
    final results = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );

    return results.map((json) => AppUser.fromLocalJson(json)).toList();
  }

  // Product Management Methods

  /// Save product locally
  Future<void> saveProduct(Product product, {bool addToSyncQueue = false}) async {
    final db = await database;
    
    await db.insert(
      'products',
      {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'category': product.category,
        'is_alcoholic': product.isAlcoholic ? 1 : 0,
        'is_in_stock': product.isInStock ? 1 : 0,
        'stock_quantity': product.stockQuantity,
        'image_url': product.imageUrl,
        'created_at': product.createdAt?.toIso8601String(),
        'updated_at': product.updatedAt?.toIso8601String(),
        'sync_status': addToSyncQueue ? 'pending' : 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (addToSyncQueue) {
      await _addToSyncQueue('products', product.id, 'insert', product.toJson());
    }

    Logger.debug('💾 Product saved locally: ${product.name}', tag: 'LocalDatabase');
  }

  /// Save multiple products
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'category': product.category,
          'is_alcoholic': product.isAlcoholic ? 1 : 0,
          'is_in_stock': product.isInStock ? 1 : 0,
          'stock_quantity': product.stockQuantity,
          'image_url': product.imageUrl,
          'created_at': product.createdAt?.toIso8601String(),
          'updated_at': product.updatedAt?.toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
    Logger.info('💾 ${products.length} products saved locally', tag: 'LocalDatabase');
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    
    final results = await db.query(
      'products',
      where: 'is_in_stock = 1',
      orderBy: 'category, name',
    );

    return results.map((json) => Product.fromLocalJson(json)).toList();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    
    final results = await db.query(
      'products',
      where: 'category = ? AND is_in_stock = 1',
      whereArgs: [category],
      orderBy: 'name',
    );

    return results.map((json) => Product.fromLocalJson(json)).toList();
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    
    final results = await db.query(
      'products',
      where: '(name LIKE ? OR description LIKE ?) AND is_in_stock = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name',
    );

    return results.map((json) => Product.fromLocalJson(json)).toList();
  }

  // Order Management Methods

  /// Save order locally
  Future<void> saveOrder(Order order, {bool addToSyncQueue = true}) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Save order
      await txn.insert(
        'orders',
        {
          'id': order.id,
          'order_number': order.orderNumber,
          'waiter_id': order.waiterId,
          'waiter_name': order.waiterName,
          'cashier_id': order.cashierId,
          'table_number': order.tableNumber,
          'customer_name': order.customerName,
          'status': order.status.name,
          'subtotal': order.subtotal,
          'tax_amount': order.taxAmount,
          'total': order.total,
          'payment_method': order.paymentMethod,
          'notes': order.notes,
          'created_at': order.createdAt.toIso8601String(),
          'approved_at': order.approvedAt?.toIso8601String(),
          'ready_at': order.readyAt?.toIso8601String(),
          'served_at': order.servedAt?.toIso8601String(),
          'updated_at': order.updatedAt?.toIso8601String(),
          'sync_status': addToSyncQueue ? 'pending' : 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save order items
      for (final item in order.items) {
        await txn.insert(
          'order_items',
          {
            'id': item.id,
            'order_id': order.id,
            'product_id': item.product.id,
            'product_name': item.product.name,
            'unit_price': item.unitPrice,
            'quantity': item.quantity,
            'total_price': item.totalPrice,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    if (addToSyncQueue) {
      await _addToSyncQueue('orders', order.id, 'insert', order.toJson());
    }

    Logger.info('💾 Order saved locally: ${order.orderNumber}', tag: 'LocalDatabase');
  }

  /// Get orders with optional filters
  Future<List<Order>> getOrders({
    OrderStatus? status,
    String? waiterId,
    int? limit,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<String> whereArgs = [];

    if (status != null) {
      whereClause += 'status = ?';
      whereArgs.add(status.name);
    }

    if (waiterId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'waiter_id = ?';
      whereArgs.add(waiterId);
    }

    final results = await db.query(
      'orders',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    final orders = <Order>[];
    
    for (final orderJson in results) {
      // Get order items
      final itemResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderJson['id']],
      );

      final items = <OrderItem>[];
      for (final itemJson in itemResults) {
        // Create product from order item data
        final product = Product(
          id: itemJson['product_id'] as String,
          name: itemJson['product_name'] as String,
          sku: itemJson['product_sku'] as String? ?? 'SKU-${itemJson['product_id']}',
          price: itemJson['unit_price'] as double,
          category: itemJson['product_category'] as String? ?? '', // Not stored in order items
          isAlcoholic: itemJson['is_alcoholic'] == 1 || itemJson['is_alcoholic'] == true,
          stockQuantity: itemJson['stock_quantity'] as int? ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        items.add(OrderItem(
          id: itemJson['id'] as String,
          product: product,
          quantity: itemJson['quantity'] as int,
          unitPrice: itemJson['unit_price'] as double,
          totalPrice: itemJson['total_price'] as double,
        ));
      }

      orders.add(Order.fromLocalJson(orderJson, items));
    }

    return orders;
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status, {
    String? cashierId,
    bool addToSyncQueue = true,
  }) async {
    final db = await database;
    
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': addToSyncQueue ? 'pending' : 'synced',
    };

    // Add status-specific timestamps
    switch (status) {
      case OrderStatus.approved:
        updates['approved_at'] = DateTime.now().toIso8601String();
        if (cashierId != null) updates['cashier_id'] = cashierId;
        break;
      case OrderStatus.ready:
        updates['ready_at'] = DateTime.now().toIso8601String();
        break;
      case OrderStatus.served:
        updates['served_at'] = DateTime.now().toIso8601String();
        break;
      default:
        break;
    }

    await db.update(
      'orders',
      updates,
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (addToSyncQueue) {
      await _addToSyncQueue('orders', orderId, 'update', updates);
    }

    Logger.info('💾 Order status updated locally: $orderId -> ${status.name}', tag: 'LocalDatabase');
  }

  // Sync Queue Methods

  /// Add record to sync queue
  Future<void> _addToSyncQueue(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    final db = await database;
    
    await db.insert('sync_queue', {
      'id': _uuid.v4(),
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });

    Logger.debug('📝 Added to sync queue: $tableName.$recordId ($operation)', tag: 'LocalDatabase');
  }

  /// Get pending sync records
  Future<List<Map<String, dynamic>>> getPendingSyncRecords() async {
    final db = await database;
    
    return await db.query(
      'sync_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  /// Mark sync record as completed
  Future<void> markSyncCompleted(String syncId) async {
    final db = await database;
    
    await db.update(
      'sync_queue',
      {
        'synced': 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  /// Update sync attempt
  Future<void> updateSyncAttempt(String syncId) async {
    final db = await database;
    
    await db.update(
      'sync_queue',
      {
        'sync_attempts': sql('sync_attempts + 1'),
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  // Settings Methods

  /// Save setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    Logger.debug('⚙️ Setting saved: $key = $value', tag: 'LocalDatabase');
  }

  /// Get setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  /// Delete all data (for fresh sync)
  Future<void> clearAllData() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete('users');
      await txn.delete('products');
      await txn.delete('orders');
      await txn.delete('order_items');
      await txn.delete('sync_queue');
    });

    Logger.warning('🗑️ All local data cleared', tag: 'LocalDatabase');
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final stats = <String, int>{};
    
    final tables = ['users', 'products', 'orders', 'order_items', 'sync_queue'];
    
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = result.first['count'] as int;
    }

    return stats;
  }
}

/// Extensions for converting between app models and local database

extension AppUserLocalExtension on AppUser {
  static AppUser fromLocalJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.waiter,
      ),
      isActive: (json['is_active'] as int) == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

extension ProductLocalExtension on Product {
  static Product fromLocalJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'] ?? 'SKU-${json['id']}',
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      isAlcoholic: (json['is_alcoholic'] as int?) == 1,
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}

extension OrderLocalExtension on Order {
  static Order fromLocalJson(Map<String, dynamic> json, List<OrderItem> items) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      waiterId: json['waiter_id'],
      waiterName: json['waiter_name'],
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
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      readyAt: json['ready_at'] != null ? DateTime.parse(json['ready_at']) : null,
      servedAt: json['served_at'] != null ? DateTime.parse(json['served_at']) : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}