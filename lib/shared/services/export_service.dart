import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/order.dart';
import '../models/app_user.dart';

class ExportService {
  static const String _spreadsheetName = 'Prime POS Data Export';
  
  // Google API Credentials (In production, store these securely)
  static const String _clientId = 'your-client-id.googleusercontent.com';
  static const String _clientSecret = 'your-client-secret';
  
  static const List<String> _scopes = [
    sheets.SheetsApi.spreadsheetsScope,
    drive.DriveApi.driveFileScope,
  ];

  /// Export orders to CSV file
  static Future<String> exportOrdersToCSV(List<Order> orders) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'prime_pos_orders_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      // Prepare CSV data
      List<List<String>> csvData = [
        // Header row
        [
          'Order Number',
          'Date',
          'Time',
          'Customer Name',
          'Table Number',
          'Waiter',
          'Status',
          'Items',
          'Subtotal',
          'Tax',
          'Total',
          'Payment Method',
          'Preparation Area',
          'Kitchen Started',
          'Kitchen Ready',
          'Served At',
        ]
      ];

      // Data rows
      for (final order in orders) {
        final items = order.items.map((item) => 
          '${item.quantity}x ${item.product.name} (₱${item.product.price})'
        ).join('; ');

        csvData.add([
          order.orderNumber,
          order.createdAt.toIso8601String().split('T')[0],
          order.createdAt.toIso8601String().split('T')[1].split('.')[0],
          order.customerName ?? '',
          order.tableNumber?.toString() ?? '',
          order.waiterName,
          order.status.name,
          items,
          order.subtotal.toStringAsFixed(2),
          order.taxAmount.toStringAsFixed(2),
          order.total.toStringAsFixed(2),
          order.paymentMethod?.name ?? '',
          order.items.first.product.preparationArea.name,
          order.prepStartedAt?.toIso8601String() ?? '',
          order.readyAt?.toIso8601String() ?? '',
          order.servedAt?.toIso8601String() ?? '',
        ]);
      }

      // Write to file
      final file = File(filePath);
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export orders to CSV: $e');
    }
  }

  /// Export users to CSV file
  static Future<String> exportUsersToCSV(List<AppUser> users) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'prime_pos_users_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      // Prepare CSV data
      List<List<String>> csvData = [
        // Header row
        [
          'Employee ID',
          'Full Name',
          'Email',
          'Role',
          'Phone Number',
          'Address',
          'Status',
          'Created Date',
          'Last Login',
        ]
      ];

      // Data rows
      for (final user in users) {
        csvData.add([
          user.employeeId ?? '',
          user.displayName,
          user.email,
          user.role.displayName,
          user.phoneNumber ?? '',
          user.address ?? '',
          user.isActive ? 'Active' : 'Inactive',
          user.createdAt.toIso8601String().split('T')[0],
          user.lastLoginAt?.toIso8601String().split('T')[0] ?? '',
        ]);
      }

      // Write to file
      final file = File(filePath);
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export users to CSV: $e');
    }
  }

  /// Export orders to Excel file
  static Future<String> exportOrdersToExcel(List<Order> orders) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'prime_pos_orders_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      // Header row
      final headers = [
        'Order Number', 'Date', 'Time', 'Customer Name', 'Table Number',
        'Waiter', 'Status', 'Items', 'Subtotal', 'Tax', 'Total',
        'Payment Method', 'Preparation Area', 'Kitchen Started', 'Kitchen Ready', 'Served At'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
      }

      // Data rows
      for (int orderIndex = 0; orderIndex < orders.length; orderIndex++) {
        final order = orders[orderIndex];
        final rowIndex = orderIndex + 1;
        
        final items = order.items.map((item) => 
          '${item.quantity}x ${item.product.name} (₱${item.product.price})'
        ).join('; ');

        final rowData = [
          order.orderNumber,
          order.createdAt.toIso8601String().split('T')[0],
          order.createdAt.toIso8601String().split('T')[1].split('.')[0],
          order.customerName ?? '',
          order.tableNumber?.toString() ?? '',
          order.waiterName,
          order.status.name,
          items,
          order.subtotal.toStringAsFixed(2),
          order.taxAmount.toStringAsFixed(2),
          order.total.toStringAsFixed(2),
          order.paymentMethod?.name ?? '',
          order.items.first.product.preparationArea.name,
          order.prepStartedAt?.toIso8601String() ?? '',
          order.readyAt?.toIso8601String() ?? '',
          order.servedAt?.toIso8601String() ?? '',
        ];

        for (int i = 0; i < rowData.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex))
            .value = TextCellValue(rowData[i]);
        }
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export orders to Excel: $e');
    }
  }

  /// Share exported file
  static Future<void> shareFile(String filePath, String fileName) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Prime POS Export: $fileName',
        text: 'Exported data from Prime POS system',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  /// Open exported file
  static Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      throw Exception('Failed to open file: $e');
    }
  }

  /// Export to Google Sheets (requires authentication)
  static Future<String> exportOrdersToGoogleSheets(
    List<Order> orders,
    AuthClient authClient,
  ) async {
    try {
      final sheetsApi = sheets.SheetsApi(authClient);
      final driveApi = drive.DriveApi(authClient);

      // Create new spreadsheet
      final spreadsheet = sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(
          title: '$_spreadsheetName - ${DateTime.now().toIso8601String().split('T')[0]}',
        ),
      );

      final createdSpreadsheet = await sheetsApi.spreadsheets.create(spreadsheet);
      final spreadsheetId = createdSpreadsheet.spreadsheetId!;

      // Prepare data
      List<List<Object?>> sheetData = [
        // Header row
        [
          'Order Number', 'Date', 'Time', 'Customer Name', 'Table Number',
          'Waiter', 'Status', 'Items', 'Subtotal', 'Tax', 'Total',
          'Payment Method', 'Preparation Area', 'Kitchen Started', 'Kitchen Ready', 'Served At'
        ]
      ];

      // Data rows
      for (final order in orders) {
        final items = order.items.map((item) => 
          '${item.quantity}x ${item.product.name} (₱${item.product.price})'
        ).join('; ');

        sheetData.add([
          order.orderNumber,
          order.createdAt.toIso8601String().split('T')[0],
          order.createdAt.toIso8601String().split('T')[1].split('.')[0],
          order.customerName ?? '',
          order.tableNumber?.toString() ?? '',
          order.waiterName,
          order.status.name,
          items,
          order.subtotal,
          order.taxAmount,
          order.total,
          order.paymentMethod?.name ?? '',
          order.items.first.product.preparationArea.name,
          order.prepStartedAt?.toIso8601String() ?? '',
          order.readyAt?.toIso8601String() ?? '',
          order.servedAt?.toIso8601String() ?? '',
        ]);
      }

      // Update sheet with data
      final valueRange = sheets.ValueRange(
        values: sheetData,
      );

      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        'Sheet1!A1:P${sheetData.length}',
        valueInputOption: 'USER_ENTERED',
      );

      // Make the spreadsheet shareable
      await driveApi.permissions.create(
        drive.Permission(
          role: 'reader',
          type: 'anyone',
        ),
        spreadsheetId,
      );

      // Return the shareable URL
      return 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';
    } catch (e) {
      throw Exception('Failed to export to Google Sheets: $e');
    }
  }

  /// Generate sales report data
  static Map<String, dynamic> generateSalesReport(List<Order> orders) {
    if (orders.isEmpty) {
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'averageOrderValue': 0.0,
        'topProducts': <String, int>{},
        'hourlyBreakdown': <String, double>{},
        'paymentMethodBreakdown': <String, int>{},
      };
    }

    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.total);
    final averageOrderValue = totalRevenue / totalOrders;

    // Top products
    final productCounts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        productCounts[item.product.name] = (productCounts[item.product.name] ?? 0) + item.quantity;
      }
    }

    // Sort and get top 10
    final topProducts = Map.fromEntries(
      productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10)
    );

    // Hourly breakdown
    final hourlyBreakdown = <String, double>{};
    for (final order in orders) {
      final hour = '${order.createdAt.hour}:00';
      hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + order.total;
    }

    // Payment method breakdown
    final paymentMethodBreakdown = <String, int>{};
    for (final order in orders) {
      if (order.paymentMethod != null) {
        final method = order.paymentMethod!.name;
        paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0) + 1;
      }
    }

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'topProducts': topProducts,
      'hourlyBreakdown': hourlyBreakdown,
      'paymentMethodBreakdown': paymentMethodBreakdown,
    };
  }

  /// Generate backup JSON file
  static Future<String> generateBackupFile(
    List<Order> orders,
    List<AppUser> users,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'prime_pos_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      final backupData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'restaurant': 'Prime POS',
        },
        'orders': orders.map((order) => order.toJson()).toList(),
        'users': users.map((user) => user.toJson()).toList(),
      };

      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate backup file: $e');
    }
  }
}