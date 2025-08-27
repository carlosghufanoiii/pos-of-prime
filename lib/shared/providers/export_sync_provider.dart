import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/order.dart';
import '../models/app_user.dart';
import '../services/export_service.dart';
import '../services/offline_sync_service.dart';

// Connection status provider - Convert single result to list
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return [result]; // Always wrap in list
  });
});

// Offline sync status provider
final offlineSyncStatusProvider =
    StateNotifierProvider<OfflineSyncStatusNotifier, OfflineSyncStatus>((ref) {
      return OfflineSyncStatusNotifier();
    });

class OfflineSyncStatus {
  final bool isInitialized;
  final bool isSyncing;
  final Map<String, int> unsyncedCounts;
  final String? error;
  final DateTime? lastSyncAt;

  const OfflineSyncStatus({
    this.isInitialized = false,
    this.isSyncing = false,
    this.unsyncedCounts = const {},
    this.error,
    this.lastSyncAt,
  });

  OfflineSyncStatus copyWith({
    bool? isInitialized,
    bool? isSyncing,
    Map<String, int>? unsyncedCounts,
    String? error,
    DateTime? lastSyncAt,
  }) {
    return OfflineSyncStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      unsyncedCounts: unsyncedCounts ?? this.unsyncedCounts,
      error: error,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

class OfflineSyncStatusNotifier extends StateNotifier<OfflineSyncStatus> {
  OfflineSyncStatusNotifier() : super(const OfflineSyncStatus()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await OfflineSyncService.initialize();
      await _updateStats();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(error: 'Initialization failed: $e');
    }
  }

  Future<void> _updateStats() async {
    try {
      final stats = await OfflineSyncService.getOfflineStats();
      state = state.copyWith(unsyncedCounts: stats);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update stats: $e');
    }
  }

  Future<void> startSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final isConnected = await OfflineSyncService.isConnected();
      if (!isConnected) {
        state = state.copyWith(
          isSyncing: false,
          error: 'No internet connection',
        );
        return;
      }

      final pendingItems = await OfflineSyncService.getPendingSyncItems();

      for (final item in pendingItems) {
        try {
          // In a real app, sync with actual backend here
          // For now, just mark as synced
          await OfflineSyncService.markItemSynced(
            item['id'] as int,
            item['entity_type'] as String,
            item['entity_id'] as String,
          );
        } catch (e) {
          await OfflineSyncService.incrementRetryCount(item['id'] as int);
        }
      }

      await _updateStats();
      state = state.copyWith(isSyncing: false, lastSyncAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: 'Sync failed: $e');
    }
  }

  Future<void> saveOrderOffline(Order order) async {
    try {
      await OfflineSyncService.saveOrderOffline(order);
      await _updateStats();
    } catch (e) {
      state = state.copyWith(error: 'Failed to save order offline: $e');
    }
  }

  Future<void> updateOrderOffline(Order order) async {
    try {
      await OfflineSyncService.updateOrderOffline(order);
      await _updateStats();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update order offline: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Export provider
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((
  ref,
) {
  return ExportNotifier();
});

class ExportState {
  final bool isExporting;
  final String? error;
  final String? successMessage;
  final String? exportedFilePath;

  const ExportState({
    this.isExporting = false,
    this.error,
    this.successMessage,
    this.exportedFilePath,
  });

  ExportState copyWith({
    bool? isExporting,
    String? error,
    String? successMessage,
    String? exportedFilePath,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: error,
      successMessage: successMessage,
      exportedFilePath: exportedFilePath,
    );
  }
}

class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier() : super(const ExportState());

  Future<void> exportOrdersToCSV(List<Order> orders) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final filePath = await ExportService.exportOrdersToCSV(orders);
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Orders exported to CSV successfully',
        exportedFilePath: filePath,
      );
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> exportUsersToCSV(List<AppUser> users) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final filePath = await ExportService.exportUsersToCSV(users);
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Users exported to CSV successfully',
        exportedFilePath: filePath,
      );
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> exportOrdersToExcel(List<Order> orders) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final filePath = await ExportService.exportOrdersToExcel(orders);
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Orders exported to Excel successfully',
        exportedFilePath: filePath,
      );
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> generateBackupFile(
    List<Order> orders,
    List<AppUser> users,
  ) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final filePath = await ExportService.generateBackupFile(orders, users);
      state = state.copyWith(
        isExporting: false,
        successMessage: 'Backup file created successfully',
        exportedFilePath: filePath,
      );
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> shareFile(String filePath, String fileName) async {
    try {
      await ExportService.shareFile(filePath, fileName);
      state = state.copyWith(successMessage: 'File shared successfully');
    } catch (e) {
      state = state.copyWith(error: 'Failed to share file: $e');
    }
  }

  Future<void> openFile(String filePath) async {
    try {
      await ExportService.openFile(filePath);
    } catch (e) {
      state = state.copyWith(error: 'Failed to open file: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Offline orders provider
final offlineOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return OfflineSyncService.getOfflineOrders();
});

// Offline users provider
final offlineUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  return OfflineSyncService.getOfflineUsers();
});

// Sales report provider
final salesReportProvider =
    FutureProvider.family<Map<String, dynamic>, List<Order>>((
      ref,
      orders,
    ) async {
      return ExportService.generateSalesReport(orders);
    });
