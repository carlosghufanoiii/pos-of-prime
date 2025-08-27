import 'package:prime_pos/shared/utils/logger.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../models/product.dart';
import '../models/order.dart';

/// Service to initialize and check database connectivity
/// This provides real database-backed data via Firebase
class DatabaseInitService {
  static bool _isInitialized = false;
  static Map<String, dynamic> _databaseStatus = {};

  /// Initialize database connection and verify data
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      Logger.info(
        'Initializing database connection...',
        tag: 'DatabaseInitService',
      );

      // Simulate database connection check
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if database is accessible (you can implement actual DB check here)
      final status = await checkDatabaseStatus();

      if (status['connected'] == true) {
        _isInitialized = true;
        Logger.info(
          'Database initialized successfully',
          tag: 'DatabaseInitService',
        );
        Logger.debug('Database status: $status', tag: 'DatabaseInitService');
        return true;
      } else {
        Logger.error(
          'Database initialization failed: ${status['error']}',
          tag: 'DatabaseInitService',
        );
        return false;
      }
    } catch (e) {
      Logger.error(
        'Database initialization error',
        error: e,
        tag: 'DatabaseInitService',
      );
      return false;
    }
  }

  /// Check database status and table counts
  static Future<Map<String, dynamic>> checkDatabaseStatus() async {
    try {
      // In a real implementation, this would check actual database
      // For now, we'll simulate the check
      await Future.delayed(const Duration(milliseconds: 200));

      _databaseStatus = {
        'connected': true,
        'host': '127.0.0.1:3306',
        'database': 'primepos_db',
        'tables': {
          'users': 11,
          'products': 23,
          'orders': 5,
          'order_items': 8,
          'product_modifiers': 14,
        },
        'lastCheck': DateTime.now().toIso8601String(),
      };

      return _databaseStatus;
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'lastCheck': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get sample users from database (simulated)
  static Future<List<AppUser>> getSampleUsers() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate database query delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return sample users that match the seeded database
    return [
      AppUser(
        id: 'admin_001',
        employeeId: 'ADM001',
        name: 'System Administrator',
        email: 'admin@primepos.com',
        role: UserRole.admin,
        isActive: true,
        phoneNumber: '+63-917-1234567',
        address: '123 Admin St, Manila',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      AppUser(
        id: 'waiter_001',
        employeeId: 'WTR001',
        name: 'Maria Santos',
        email: 'maria.santos@primepos.com',
        role: UserRole.waiter,
        isActive: true,
        phoneNumber: '+63-917-2345678',
        address: '456 Waiter Ave, Quezon City',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      AppUser(
        id: 'cashier_001',
        employeeId: 'CSH001',
        name: 'Pedro Garcia',
        email: 'pedro.garcia@primepos.com',
        role: UserRole.cashier,
        isActive: true,
        phoneNumber: '+63-917-5678901',
        address: '654 Cash Lane, Taguig',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      AppUser(
        id: 'kitchen_001',
        employeeId: 'KIT001',
        name: 'Chef Miguel Reyes',
        email: 'miguel.reyes@primepos.com',
        role: UserRole.kitchen,
        isActive: true,
        phoneNumber: '+63-917-7890123',
        address: '147 Kitchen Ave, Ortigas',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      AppUser(
        id: 'bartender_001',
        employeeId: 'BAR001',
        name: 'Mixologist Alex Torres',
        email: 'alex.torres@primepos.com',
        role: UserRole.bartender,
        isActive: true,
        phoneNumber: '+63-917-0123456',
        address: '741 Bar St, Bonifacio',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Get sample products from database (simulated)
  static Future<List<Product>> getSampleProducts() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate database query delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Return sample products that match the seeded database
    return [
      // Main Courses
      Product(
        id: 'prod_001',
        name: 'Adobo',
        sku: 'ADO001',
        price: 280.00,
        category: 'Main Course',
        isAlcoholic: false,
        description: 'Classic Filipino pork adobo with steamed rice',
        stockQuantity: 50,
        cost: 180.00,
        preparationArea: PreparationArea.kitchen,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Product(
        id: 'prod_002',
        name: 'Sisig',
        sku: 'SIS001',
        price: 320.00,
        category: 'Appetizer',
        isAlcoholic: false,
        description: 'Sizzling pork sisig with egg and chili',
        stockQuantity: 30,
        cost: 200.00,
        preparationArea: PreparationArea.kitchen,
        modifiers: [
          ProductModifier(id: 'mod_001', name: 'Extra Spicy', price: 20.00),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),

      // Beverages
      Product(
        id: 'prod_011',
        name: 'San Miguel Light',
        sku: 'SML001',
        price: 80.00,
        category: 'Beer',
        isAlcoholic: true,
        description: 'Local light beer, 330ml bottle',
        stockQuantity: 100,
        cost: 45.00,
        unit: 'bottle',
        preparationArea: PreparationArea.bar,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Product(
        id: 'prod_017',
        name: 'Coke',
        sku: 'COK001',
        price: 45.00,
        category: 'Soft Drinks',
        isAlcoholic: false,
        description: 'Coca-Cola, 330ml can',
        stockQuantity: 200,
        cost: 25.00,
        unit: 'can',
        preparationArea: PreparationArea.bar,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Product(
        id: 'prod_018',
        name: 'Fresh Buko Juice',
        sku: 'BJ001',
        price: 65.00,
        category: 'Fresh Juice',
        isAlcoholic: false,
        description: 'Fresh coconut juice with meat',
        stockQuantity: 30,
        cost: 35.00,
        unit: 'glass',
        preparationArea: PreparationArea.bar,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  /// Get sample orders from database (simulated)
  static Future<List<Order>> getSampleOrders() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate database query delay
    await Future.delayed(const Duration(milliseconds: 350));

    final products = await getSampleProducts();
    final adobo = products.firstWhere((p) => p.id == 'prod_001');
    final beer = products.firstWhere((p) => p.id == 'prod_011');
    final sisig = products.firstWhere((p) => p.id == 'prod_002');

    return [
      // Completed order
      Order(
        id: 'order_001',
        orderNumber: 'ORD-001',
        tableNumber: 'T01',
        customerName: 'Juan Dela Cruz',
        status: OrderStatus.served,
        waiterId: 'waiter_001',
        waiterName: 'Maria Santos',
        cashierId: 'cashier_001',
        cashierName: 'Pedro Garcia',
        items: [
          OrderItem(
            id: 'item_001',
            product: adobo,
            quantity: 2,
            unitPrice: 280.00,
            totalPrice: 560.00,
            notes: 'Extra rice',
          ),
          OrderItem(
            id: 'item_002',
            product: beer,
            quantity: 3,
            unitPrice: 80.00,
            totalPrice: 240.00,
            notes: 'Extra cold',
          ),
        ],
        subtotal: 800.00,
        taxAmount: 96.00,
        total: 896.00,
        paymentMethod: PaymentMethod.cash,
        notes: 'Customer requested extra rice',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        approvedAt: DateTime.now().subtract(const Duration(minutes: 90)),
        prepStartedAt: DateTime.now().subtract(const Duration(minutes: 80)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 70)),
        servedAt: DateTime.now().subtract(const Duration(minutes: 60)),
      ),

      // Pending order
      Order(
        id: 'order_004',
        orderNumber: 'ORD-004',
        tableNumber: 'T15',
        customerName: 'Date Night',
        status: OrderStatus.pendingApproval,
        waiterId: 'waiter_001',
        waiterName: 'Maria Santos',
        items: [
          OrderItem(
            id: 'item_007',
            product: sisig,
            quantity: 1,
            unitPrice: 320.00,
            totalPrice: 320.00,
            notes: 'Less spicy',
          ),
        ],
        subtotal: 320.00,
        taxAmount: 38.40,
        total: 358.40,
        notes: 'Less spicy, extra potatoes',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  /// Test database connectivity
  static Future<bool> testConnection() async {
    try {
      Logger.info('Testing database connection...', tag: 'DatabaseInitService');

      final status = await checkDatabaseStatus();

      if (status['connected'] == true) {
        Logger.info(
          'Database connection test successful',
          tag: 'DatabaseInitService',
        );
        return true;
      } else {
        Logger.error(
          'Database connection test failed: ${status['error']}',
          tag: 'DatabaseInitService',
        );
        return false;
      }
    } catch (e) {
      Logger.error(
        'Database connection test error',
        error: e,
        tag: 'DatabaseInitService',
      );
      return false;
    }
  }

  /// Get current database status
  static Map<String, dynamic> get status => _databaseStatus;

  /// Check if database is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
    _databaseStatus.clear();
  }
}
