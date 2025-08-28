import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/order.dart';
import '../models/app_user.dart';
import '../utils/logger.dart';
import 'google_drive_service.dart';

class ExportService {
  /// Export orders to CSV file with automatic Google Drive upload
  static Future<String> exportOrdersToCSV(
    List<Order> orders, {
    bool autoUploadToDrive = true,
  }) async {
    try {
      Logger.info(
        '📊 Exporting ${orders.length} orders to CSV',
        tag: 'ExportService',
      );

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
        ],
      ];

      // Data rows
      for (final order in orders) {
        final items = order.items
            .map(
              (item) =>
                  '${item.quantity}x ${item.product.name} (₱${item.unitPrice})',
            )
            .join('; ');

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

      Logger.info('✅ CSV file created: $fileName', tag: 'ExportService');

      // Auto-upload to Google Drive
      if (autoUploadToDrive) {
        try {
          Logger.info('☁️ Uploading CSV to Google Drive', tag: 'ExportService');
          final driveUrl = await GoogleDriveService.instance.uploadCSVFile(
            filePath,
            fileName,
            description:
                'Prime POS Orders Export - ${DateTime.now().toLocal()}',
          );

          if (driveUrl != null) {
            Logger.info(
              '✅ CSV uploaded to Google Drive successfully',
              tag: 'ExportService',
            );
          }
        } catch (e) {
          Logger.warning(
            '⚠️ Failed to upload CSV to Google Drive: $e',
            tag: 'ExportService',
          );
          // Continue execution - local file is still available
        }
      }

      return filePath;
    } catch (e) {
      Logger.error(
        '❌ Failed to export orders to CSV',
        error: e,
        tag: 'ExportService',
      );
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
        ],
      ];

      // Data rows
      for (final user in users) {
        csvData.add([
          user.employeeId ?? '',
          user.name,
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

  /// Export orders to Excel file with automatic Google Drive upload
  static Future<String> exportOrdersToExcel(
    List<Order> orders, {
    bool autoUploadToDrive = true,
  }) async {
    try {
      Logger.info(
        '📊 Exporting ${orders.length} orders to Excel',
        tag: 'ExportService',
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'prime_pos_orders_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      // Header row with styling
      final headers = [
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
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        // Add header styling (basic bold formatting)
        cell.cellStyle = CellStyle(bold: true);
      }

      // Data rows
      for (int orderIndex = 0; orderIndex < orders.length; orderIndex++) {
        final order = orders[orderIndex];
        final rowIndex = orderIndex + 1;

        final items = order.items
            .map(
              (item) =>
                  '${item.quantity}x ${item.product.name} (₱${item.unitPrice})',
            )
            .join('; ');

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
          sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            rowData[i],
          );
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      Logger.info('✅ Excel file created: $fileName', tag: 'ExportService');

      // Auto-upload to Google Drive
      if (autoUploadToDrive) {
        try {
          Logger.info(
            '☁️ Uploading Excel to Google Drive',
            tag: 'ExportService',
          );
          final driveUrl = await GoogleDriveService.instance.uploadExcelFile(
            filePath,
            fileName,
            description:
                'Prime POS Orders Excel Export - ${DateTime.now().toLocal()}',
          );

          if (driveUrl != null) {
            Logger.info(
              '✅ Excel uploaded to Google Drive successfully',
              tag: 'ExportService',
            );
          }
        } catch (e) {
          Logger.warning(
            '⚠️ Failed to upload Excel to Google Drive: $e',
            tag: 'ExportService',
          );
          // Continue execution - local file is still available
        }
      }

      return filePath;
    } catch (e) {
      Logger.error(
        '❌ Failed to export orders to Excel',
        error: e,
        tag: 'ExportService',
      );
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
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final averageOrderValue = totalRevenue / totalOrders;

    // Top products
    final productCounts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        productCounts[item.product.name] =
            (productCounts[item.product.name] ?? 0) + item.quantity;
      }
    }

    // Sort and get top 10
    final topProducts = Map.fromEntries(
      productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10),
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
        paymentMethodBreakdown[method] =
            (paymentMethodBreakdown[method] ?? 0) + 1;
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

  /// Generate backup JSON file with automatic Google Drive upload
  static Future<String> generateBackupFile(
    List<Order> orders,
    List<AppUser> users, {
    bool autoUploadToDrive = true,
  }) async {
    try {
      Logger.info(
        '💾 Generating backup for ${orders.length} orders and ${users.length} users',
        tag: 'ExportService',
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final fileName = 'prime_pos_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      final backupData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'restaurant': 'Prime POS',
          'totalOrders': orders.length,
          'totalUsers': users.length,
          'backupType': 'complete_system_backup',
        },
        'orders': orders.map((order) => order.toJson()).toList(),
        'users': users.map((user) => user.toJson()).toList(),
        'statistics': generateSalesReport(orders),
      };

      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      Logger.info('✅ Backup file created: $fileName', tag: 'ExportService');

      // Auto-upload to Google Drive
      if (autoUploadToDrive) {
        try {
          Logger.info(
            '☁️ Uploading backup to Google Drive',
            tag: 'ExportService',
          );
          final driveUrl = await GoogleDriveService.instance.uploadBackupFile(
            filePath,
            fileName,
            description:
                'Prime POS Complete System Backup - ${DateTime.now().toLocal()}',
          );

          if (driveUrl != null) {
            Logger.info(
              '✅ Backup uploaded to Google Drive successfully',
              tag: 'ExportService',
            );

            // Schedule cleanup of old backups
            Future.microtask(
              () => GoogleDriveService.instance.cleanupOldBackups(),
            );
          }
        } catch (e) {
          Logger.warning(
            '⚠️ Failed to upload backup to Google Drive: $e',
            tag: 'ExportService',
          );
          // Continue execution - local backup is still available
        }
      }

      return filePath;
    } catch (e) {
      Logger.error(
        '❌ Failed to generate backup file',
        error: e,
        tag: 'ExportService',
      );
      throw Exception('Failed to generate backup file: $e');
    }
  }

  /// Initialize automatic nightly backups to Google Drive
  static Future<bool> initializeAutomaticBackups({
    required Future<List<Order>> Function() getOrders,
    required Future<List<AppUser>> Function() getUsers,
  }) async {
    try {
      Logger.info(
        '🌙 Initializing automatic nightly backups',
        tag: 'ExportService',
      );

      // Schedule automatic backups
      final success = await GoogleDriveService.instance.scheduleNightlyBackup(
        backupGenerator: () async {
          final orders = await getOrders();
          final users = await getUsers();

          // Generate backup file (without auto-upload since the service handles upload)
          return await generateBackupFile(
            orders,
            users,
            autoUploadToDrive: false,
          );
        },
      );

      if (success) {
        Logger.info(
          '✅ Automatic nightly backups initialized',
          tag: 'ExportService',
        );
      } else {
        Logger.warning(
          '⚠️ Failed to initialize automatic backups',
          tag: 'ExportService',
        );
      }

      return success;
    } catch (e) {
      Logger.error(
        '❌ Error initializing automatic backups',
        error: e,
        tag: 'ExportService',
      );
      return false;
    }
  }
}
