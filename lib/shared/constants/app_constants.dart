class AppConstants {
  // App Info
  static const String appName = 'Prime Bar POS';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Alatiris Inc.';
  
  // Locale and Currency
  static const String locale = 'en_PH';
  static const String timezone = 'Asia/Manila';
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  
  // Tax Configuration
  static const double vatRate = 0.12; // 12% VAT in Philippines
  static const double defaultServiceChargeRate = 0.10; // 10% service charge
  
  // Order Configuration
  static const int maxOrderItems = 100;
  static const int maxTableNumber = 999;
  static const Duration orderTimeout = Duration(minutes: 30);
  
  // Printing Configuration
  static const int thermalPrinterWidth58mm = 32; // characters per line
  static const int thermalPrinterWidth80mm = 48; // characters per line
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String inventoryCollection = 'inventory';
  static const String categoriesCollection = 'categories';
  static const String tablesCollection = 'tables';
  static const String reportsCollection = 'reports';
  
  // Local Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String offlineOrdersKey = 'offline_orders';
  static const String cachedProductsKey = 'cached_products';
  static const String printerSettingsKey = 'printer_settings';
  
  // Google Integration
  static const String googleSheetsScope = 'https://www.googleapis.com/auth/spreadsheets';
  static const String googleDriveScope = 'https://www.googleapis.com/auth/drive.file';
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String permissionErrorMessage = 'You do not have permission to perform this action.';
  static const String printerErrorMessage = 'Printer connection failed. Please check your printer settings.';
  
  // Success Messages
  static const String orderCreatedMessage = 'Order created successfully';
  static const String orderApprovedMessage = 'Order approved and sent to kitchen/bar';
  static const String paymentProcessedMessage = 'Payment processed successfully';
  static const String receiptPrintedMessage = 'Receipt printed successfully';
}