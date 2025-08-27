import 'dart:async';
import 'dart:convert';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'network_service.dart';
import 'local_database_service.dart';
import 'lan_api_service.dart';
import 'firebase_database_service.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

enum ConflictResolution {
  localWins,    // Use local version
  remoteWins,   // Use remote version
  merge,        // Attempt to merge changes
  manual,       // Requires manual resolution
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  final NetworkService _networkService = NetworkService.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final LanApiService _lanApi = LanApiService.instance;
  final FirebaseDatabaseService _firebaseDb = FirebaseDatabaseService();

  // Sync state
  SyncStatus _status = SyncStatus.idle;
  String? _currentSyncOperation;
  DateTime? _lastSyncTime;
  Map<String, dynamic> _syncStats = {};

  // Stream controllers
  final StreamController<SyncStatus> _statusController = 
      StreamController<SyncStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _progressController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  SyncStatus get status => _status;
  String? get currentOperation => _currentSyncOperation;
  DateTime? get lastSyncTime => _lastSyncTime;
  Map<String, dynamic> get syncStats => Map.from(_syncStats);

  // Streams
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;

  /// Initialize sync service
  Future<void> initialize() async {
    Logger.info('🔄 Initializing Sync Service', tag: 'SyncService');

    // Listen to network changes
    _networkService.networkStatusStream.listen(_handleNetworkChange);

    // Load last sync time
    final lastSyncString = await _localDb.getSetting('last_sync_time');
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
    }

    // Start periodic sync when connected
    _startPeriodicSync();

    Logger.info('✅ Sync Service initialized', tag: 'SyncService');
  }

  /// Handle network status changes
  void _handleNetworkChange(NetworkStatus status) {
    Logger.info('📡 Network status changed: ${status.name}', tag: 'SyncService');

    switch (status) {
      case NetworkStatus.full:
      case NetworkStatus.internetOnly:
      case NetworkStatus.wifiOnly:
        // Trigger sync when connectivity is restored
        if (_status == SyncStatus.idle) {
          Future.delayed(const Duration(seconds: 2), () => syncAll());
        }
        break;
      case NetworkStatus.offline:
        // Stop any ongoing sync
        if (_status == SyncStatus.syncing) {
          _updateSyncStatus(SyncStatus.failed);
        }
        break;
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_networkService.hasInternetAccess || _networkService.hasWifiAccess) {
        if (_status == SyncStatus.idle) {
          syncPendingChanges();
        }
      }
    });
  }

  /// Sync all data (full sync)
  Future<bool> syncAll({bool forceSync = false}) async {
    if (_status == SyncStatus.syncing && !forceSync) {
      Logger.warning('⚠️ Sync already in progress', tag: 'SyncService');
      return false;
    }

    Logger.info('🔄 Starting full sync...', tag: 'SyncService');
    _updateSyncStatus(SyncStatus.syncing);
    _updateProgress('Starting sync...', 0);

    try {
      // Step 1: Sync pending local changes first
      await _syncPendingChanges();
      _updateProgress('Synced pending changes', 25);

      // Step 2: Pull latest data from remote
      await _pullDataFromRemote();
      _updateProgress('Pulled remote data', 50);

      // Step 3: Push any remaining local changes
      await _pushLocalChanges();
      _updateProgress('Pushed local changes', 75);

      // Step 4: Update sync metadata
      _lastSyncTime = DateTime.now();
      await _localDb.saveSetting('last_sync_time', _lastSyncTime!.toIso8601String());
      _updateProgress('Sync completed', 100);

      _updateSyncStatus(SyncStatus.completed);
      Logger.info('✅ Full sync completed successfully', tag: 'SyncService');
      return true;

    } catch (e) {
      Logger.error('❌ Full sync failed', error: e, tag: 'SyncService');
      _updateSyncStatus(SyncStatus.failed);
      _updateProgress('Sync failed: ${e.toString()}', 0);
      return false;
    }
  }

  /// Sync only pending local changes
  Future<bool> syncPendingChanges() async {
    if (_status == SyncStatus.syncing) {
      return false;
    }

    Logger.info('📤 Syncing pending changes...', tag: 'SyncService');
    _updateSyncStatus(SyncStatus.syncing);

    try {
      await _syncPendingChanges();
      _updateSyncStatus(SyncStatus.completed);
      Logger.info('✅ Pending changes synced', tag: 'SyncService');
      return true;
    } catch (e) {
      Logger.error('❌ Failed to sync pending changes', error: e, tag: 'SyncService');
      _updateSyncStatus(SyncStatus.failed);
      return false;
    }
  }

  /// Pull latest data from remote server
  Future<bool> pullFromRemote() async {
    if (_status == SyncStatus.syncing) {
      return false;
    }

    Logger.info('📥 Pulling data from remote...', tag: 'SyncService');
    _updateSyncStatus(SyncStatus.syncing);

    try {
      await _pullDataFromRemote();
      _updateSyncStatus(SyncStatus.completed);
      Logger.info('✅ Data pulled from remote', tag: 'SyncService');
      return true;
    } catch (e) {
      Logger.error('❌ Failed to pull from remote', error: e, tag: 'SyncService');
      _updateSyncStatus(SyncStatus.failed);
      return false;
    }
  }

  /// Internal method to sync pending changes
  Future<void> _syncPendingChanges() async {
    final pendingRecords = await _localDb.getPendingSyncRecords();
    
    if (pendingRecords.isEmpty) {
      Logger.debug('No pending changes to sync', tag: 'SyncService');
      return;
    }

    Logger.info('📤 Syncing ${pendingRecords.length} pending changes', tag: 'SyncService');

    int syncedCount = 0;
    for (final record in pendingRecords) {
      try {
        await _syncRecord(record);
        await _localDb.markSyncCompleted(record['id']);
        syncedCount++;
      } catch (e) {
        Logger.error('❌ Failed to sync record: ${record['id']}', error: e, tag: 'SyncService');
        await _localDb.updateSyncAttempt(record['id']);
        
        // Stop sync if too many failures
        if (record['sync_attempts'] >= 3) {
          Logger.warning('⚠️ Record exceeded max sync attempts: ${record['id']}', tag: 'SyncService');
        }
      }
    }

    Logger.info('✅ Synced $syncedCount/${pendingRecords.length} pending changes', tag: 'SyncService');
  }

  /// Sync a single record
  Future<void> _syncRecord(Map<String, dynamic> record) async {
    final tableName = record['table_name'] as String;
    final operation = record['operation'] as String;
    final data = jsonDecode(record['data'] as String) as Map<String, dynamic>;

    // Determine target service based on network status
    final useLocalServer = _networkService.isConnectedToLocalServer;

    switch (tableName) {
      case 'orders':
        await _syncOrderRecord(operation, data, useLocalServer);
        break;
      case 'products':
        await _syncProductRecord(operation, data, useLocalServer);
        break;
      case 'users':
        await _syncUserRecord(operation, data, useLocalServer);
        break;
      default:
        Logger.warning('⚠️ Unknown table for sync: $tableName', tag: 'SyncService');
    }
  }

  /// Sync order record
  Future<void> _syncOrderRecord(String operation, Map<String, dynamic> data, bool useLocalServer) async {
    switch (operation) {
      case 'insert':
        if (useLocalServer) {
          final order = Order.fromJson(data);
          await _lanApi.createOrder(order);
        } else {
          // Sync to Firebase
          await _firebaseDb.createOrder(Order.fromJson(data));
        }
        break;
      case 'update':
        final orderId = data['id'] as String;
        final status = OrderStatus.values.firstWhere((s) => s.name == data['status']);
        
        if (useLocalServer) {
          await _lanApi.updateOrderStatus(orderId, status, data['cashier_id']);
        } else {
          // Update in Firebase
          await _firebaseDb.updateOrderStatus(orderId, status, data['cashier_id']);
        }
        break;
    }
  }

  /// Sync product record
  Future<void> _syncProductRecord(String operation, Map<String, dynamic> data, bool useLocalServer) async {
    switch (operation) {
      case 'insert':
        if (useLocalServer) {
          final product = Product.fromJson(data);
          await _lanApi.createProduct(product);
        } else {
          // Sync to Firebase
          await _firebaseDb.createProduct(Product.fromJson(data));
        }
        break;
      case 'update':
        // Handle product updates
        break;
    }
  }

  /// Sync user record
  Future<void> _syncUserRecord(String operation, Map<String, dynamic> data, bool useLocalServer) async {
    switch (operation) {
      case 'insert':
        if (useLocalServer) {
          final user = AppUser.fromJson(data);
          await _lanApi.createUser(user, 'default123'); // Default password for sync
        } else {
          // Sync to Firebase
          await _firebaseDb.createUser(AppUser.fromJson(data));
        }
        break;
      case 'update':
        if (useLocalServer) {
          final user = AppUser.fromJson(data);
          await _lanApi.updateUser(user);
        } else {
          // Update in Firebase
          await _firebaseDb.updateUser(AppUser.fromJson(data));
        }
        break;
    }
  }

  /// Pull data from remote server
  Future<void> _pullDataFromRemote() async {
    final useLocalServer = _networkService.isConnectedToLocalServer;

    if (useLocalServer) {
      await _pullFromLanServer();
    } else if (_networkService.hasInternetAccess) {
      await _pullFromFirebase();
    } else {
      throw Exception('No remote server available');
    }
  }

  /// Pull data from LAN server
  Future<void> _pullFromLanServer() async {
    Logger.info('📥 Pulling data from LAN server...', tag: 'SyncService');

    // Pull products
    final products = await _lanApi.getAllProducts();
    await _localDb.saveProducts(products);
    Logger.debug('📥 Pulled ${products.length} products from LAN', tag: 'SyncService');

    // Pull orders (recent ones)
    final orders = await _lanApi.getOrders();
    for (final order in orders) {
      await _localDb.saveOrder(order, addToSyncQueue: false);
    }
    Logger.debug('📥 Pulled ${orders.length} orders from LAN', tag: 'SyncService');

    // Pull users (admin only)
    try {
      final users = await _lanApi.getAllUsers();
      for (final user in users) {
        await _localDb.saveUser(user, addToSyncQueue: false);
      }
      Logger.debug('📥 Pulled ${users.length} users from LAN', tag: 'SyncService');
    } catch (e) {
      // User might not have admin access
      Logger.debug('Could not pull users (admin access required)', tag: 'SyncService');
    }
  }

  /// Pull data from Firebase
  Future<void> _pullFromFirebase() async {
    Logger.info('📥 Pulling data from Firebase...', tag: 'SyncService');

    // Pull products
    final products = await _firebaseDb.getAllProducts();
    await _localDb.saveProducts(products);
    Logger.debug('📥 Pulled ${products.length} products from Firebase', tag: 'SyncService');

    // Pull recent orders
    final orders = await _firebaseDb.getRecentOrders();
    for (final order in orders) {
      await _localDb.saveOrder(order, addToSyncQueue: false);
    }
    Logger.debug('📥 Pulled ${orders.length} orders from Firebase', tag: 'SyncService');
  }

  /// Push local changes to remote
  Future<void> _pushLocalChanges() async {
    // This is handled by _syncPendingChanges()
    await _syncPendingChanges();
  }

  /// Handle sync conflicts
  Future<ConflictResolution> resolveConflict(
    String tableName,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    // Simple conflict resolution strategy
    // In production, you might want more sophisticated logic

    final localUpdated = DateTime.tryParse(localData['updated_at'] ?? '');
    final remoteUpdated = DateTime.tryParse(remoteData['updated_at'] ?? '');

    if (localUpdated != null && remoteUpdated != null) {
      // Use the most recently updated version
      return localUpdated.isAfter(remoteUpdated) 
          ? ConflictResolution.localWins 
          : ConflictResolution.remoteWins;
    }

    // Default to remote wins if timestamps are unclear
    return ConflictResolution.remoteWins;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final stats = await _localDb.getDatabaseStats();
    final pendingRecords = await _localDb.getPendingSyncRecords();

    return {
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'status': _status.name,
      'currentOperation': _currentSyncOperation,
      'databaseStats': stats,
      'pendingSyncRecords': pendingRecords.length,
      'networkStatus': _networkService.currentStatus.name,
      'hasLocalServer': _networkService.isConnectedToLocalServer,
      'hasInternet': _networkService.hasInternetAccess,
    };
  }

  /// Force a complete resync
  Future<bool> forceCompleteResync() async {
    Logger.warning('🔄 Starting complete resync (clearing local data)...', tag: 'SyncService');

    try {
      _updateSyncStatus(SyncStatus.syncing);
      _updateProgress('Clearing local data...', 10);

      // Clear all local data
      await _localDb.clearAllData();

      // Pull fresh data from remote
      _updateProgress('Pulling fresh data...', 50);
      await _pullDataFromRemote();

      _lastSyncTime = DateTime.now();
      await _localDb.saveSetting('last_sync_time', _lastSyncTime!.toIso8601String());

      _updateSyncStatus(SyncStatus.completed);
      _updateProgress('Complete resync finished', 100);

      Logger.info('✅ Complete resync finished', tag: 'SyncService');
      return true;

    } catch (e) {
      Logger.error('❌ Complete resync failed', error: e, tag: 'SyncService');
      _updateSyncStatus(SyncStatus.failed);
      return false;
    }
  }

  /// Update sync status
  void _updateSyncStatus(SyncStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      
      Logger.debug('📊 Sync status: ${status.name}', tag: 'SyncService');
    }
  }

  /// Update sync progress
  void _updateProgress(String operation, int percentage) {
    _currentSyncOperation = operation;
    
    final progress = {
      'operation': operation,
      'percentage': percentage,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _progressController.add(progress);
    Logger.debug('📊 Sync progress: $operation ($percentage%)', tag: 'SyncService');
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _progressController.close();
  }
}

/// Extensions for model conversion

extension OrderJsonExtension on Order {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'cashierId': cashierId,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'status': status.name,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'items': items.map((item) => {
        'id': item.id,
        'productId': item.product.id,
        'productName': item.product.name,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'totalPrice': item.totalPrice,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'servedAt': servedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Order fromJson(Map<String, dynamic> json) {
    final List<OrderItem> items = [];
    if (json['items'] != null) {
      for (final itemJson in json['items']) {
        final product = Product(
          id: itemJson['productId'] ?? '',
          name: itemJson['productName'] ?? '',
          sku: itemJson['productSku'] ?? 'SKU-${itemJson['productId']}',
          price: itemJson['unitPrice']?.toDouble() ?? 0.0,
          category: itemJson['productCategory'] ?? 'General',
          isAlcoholic: itemJson['isAlcoholic'] ?? false,
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
      orderNumber: json['orderNumber'],
      waiterId: json['waiterId'],
      waiterName: json['waiterName'],
      cashierId: json['cashierId'],
      tableNumber: json['tableNumber'],
      customerName: json['customerName'],
      items: items,
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pendingApproval,
      ),
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      taxAmount: json['taxAmount']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      readyAt: json['readyAt'] != null ? DateTime.parse(json['readyAt']) : null,
      servedAt: json['servedAt'] != null ? DateTime.parse(json['servedAt']) : null,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}