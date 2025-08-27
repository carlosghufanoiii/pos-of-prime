import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

enum NetworkStatus {
  offline,
  wifiOnly,     // Connected to WiFi but no internet
  internetOnly, // Connected to internet but no local server
  full,        // Connected to both WiFi and internet with local server
}

enum ServerType {
  local,  // Local LAN server
  cloud,  // Firebase/Cloud server
}

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Stream controllers for reactive updates
  final StreamController<NetworkStatus> _networkStatusController = 
      StreamController<NetworkStatus>.broadcast();
  final StreamController<String?> _localServerController = 
      StreamController<String?>.broadcast();

  // Current network state
  NetworkStatus _currentStatus = NetworkStatus.offline;
  String? _localServerUrl;
  String? _currentWifiSSID;
  bool _isInitialized = false;

  // Cached server info
  Map<String, dynamic>? _localServerInfo;
  DateTime? _lastServerCheck;

  // Getters
  NetworkStatus get currentStatus => _currentStatus;
  String? get localServerUrl => _localServerUrl;
  String? get currentWifiSSID => _currentWifiSSID;
  bool get isConnectedToLocalServer => _localServerUrl != null;
  bool get hasInternetAccess => _currentStatus == NetworkStatus.internetOnly || 
                                 _currentStatus == NetworkStatus.full;
  bool get hasWifiAccess => _currentStatus == NetworkStatus.wifiOnly || 
                           _currentStatus == NetworkStatus.full;

  // Streams
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
  Stream<String?> get localServerStream => _localServerController.stream;

  /// Initialize the network service
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('🌐 Initializing Network Service', tag: 'NetworkService');

    // Load saved server URL
    await _loadSavedServerUrl();

    // Start listening to connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    // Initial network check
    await _checkNetworkStatus();

    // Start periodic server discovery
    _startServerDiscovery();

    _isInitialized = true;
    Logger.info('✅ Network Service initialized', tag: 'NetworkService');
  }

  /// Dispose resources
  void dispose() {
    _networkStatusController.close();
    _localServerController.close();
    _dio.close();
  }

  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    Logger.info('📡 Connectivity changed: $results', tag: 'NetworkService');
    await _checkNetworkStatus();
  }

  /// Comprehensive network status check
  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // Check if we have any form of connectivity
      if (connectivityResults.contains(ConnectivityResult.none)) {
        await _updateNetworkStatus(NetworkStatus.offline);
        return;
      }

      // Get WiFi SSID if connected to WiFi
      await _updateWifiSSID();

      // Check local server availability
      final hasLocalServer = await _checkLocalServer();
      
      // Check internet connectivity
      final hasInternet = await _checkInternetConnectivity();

      // Determine overall network status
      NetworkStatus newStatus;
      if (hasLocalServer && hasInternet) {
        newStatus = NetworkStatus.full;
      } else if (hasLocalServer && !hasInternet) {
        newStatus = NetworkStatus.wifiOnly;
      } else if (!hasLocalServer && hasInternet) {
        newStatus = NetworkStatus.internetOnly;
      } else {
        newStatus = NetworkStatus.offline;
      }

      await _updateNetworkStatus(newStatus);

    } catch (e) {
      Logger.error('❌ Error checking network status', error: e, tag: 'NetworkService');
      await _updateNetworkStatus(NetworkStatus.offline);
    }
  }

  /// Check if local server is available
  Future<bool> _checkLocalServer() async {
    // First try saved server URL
    if (_localServerUrl != null) {
      final isReachable = await _testServerConnection(_localServerUrl!);
      if (isReachable) {
        Logger.info('✅ Local server reachable: $_localServerUrl', tag: 'NetworkService');
        return true;
      } else {
        // Clear invalid server URL
        _localServerUrl = null;
        await _clearSavedServerUrl();
      }
    }

    // If no saved server or it's unreachable, try discovery
    final discoveredServer = await _discoverLocalServer();
    if (discoveredServer != null) {
      _localServerUrl = discoveredServer;
      await _saveServerUrl(discoveredServer);
      _localServerController.add(discoveredServer);
      Logger.info('🔍 Discovered local server: $discoveredServer', tag: 'NetworkService');
      return true;
    }

    _localServerController.add(null);
    return false;
  }

  /// Test connection to a specific server URL
  Future<bool> _testServerConnection(String serverUrl) async {
    try {
      final response = await _dio.get(
        '$serverUrl/api/health',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'healthy') {
        _localServerInfo = response.data;
        _lastServerCheck = DateTime.now();
        return true;
      }
    } catch (e) {
      // Server not reachable
      Logger.debug('❌ Server not reachable: $serverUrl - $e', tag: 'NetworkService');
    }
    return false;
  }

  /// Discover local server on the network
  Future<String?> _discoverLocalServer() async {
    Logger.info('🔍 Starting local server discovery...', tag: 'NetworkService');

    try {
      // Get current device IP to determine network range
      final deviceIP = await _getDeviceIP();
      if (deviceIP == null) return null;

      final networkBase = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
      final commonPorts = [3000, 8080, 8000, 3001, 5000];

      // Scan common IP ranges and ports
      final List<Future<String?>> scanFutures = [];

      // Scan last 20 IPs in the network range
      for (int i = 1; i <= 20; i++) {
        for (final port in commonPorts) {
          final serverUrl = 'http://$networkBase.$i:$port';
          scanFutures.add(_testServerUrl(serverUrl));
        }
      }

      // Also check common server IPs
      final commonIPs = [
        '$networkBase.1',   // Router/Gateway
        '$networkBase.100', // Common server IP
        '$networkBase.101', // Common server IP  
        '$networkBase.200', // Common server IP
      ];

      for (final ip in commonIPs) {
        for (final port in commonPorts) {
          final serverUrl = 'http://$ip:$port';
          scanFutures.add(_testServerUrl(serverUrl));
        }
      }

      // Wait for first successful connection
      final results = await Future.wait(scanFutures);
      final foundServer = results.firstWhere((url) => url != null, orElse: () => null);

      if (foundServer != null) {
        Logger.info('✅ Found local server: $foundServer', tag: 'NetworkService');
        return foundServer;
      }

      Logger.info('❌ No local server found on network', tag: 'NetworkService');
      return null;

    } catch (e) {
      Logger.error('❌ Error during server discovery', error: e, tag: 'NetworkService');
      return null;
    }
  }

  /// Test a specific server URL
  Future<String?> _testServerUrl(String serverUrl) async {
    try {
      final response = await _dio.get(
        '$serverUrl/api/health',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'healthy') {
        return serverUrl;
      }
    } catch (e) {
      // Ignore errors during discovery
    }
    return null;
  }

  /// Get device IP address
  Future<String?> _getDeviceIP() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      Logger.error('❌ Error getting device IP', error: e, tag: 'NetworkService');
    }
    return null;
  }

  /// Check internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      final response = await _dio.get(
        'https://www.google.com',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update WiFi SSID
  Future<void> _updateWifiSSID() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        // Note: Getting SSID requires special permissions on mobile
        // For now, we'll just indicate WiFi is connected
        _currentWifiSSID = 'WiFi Connected';
      } else {
        _currentWifiSSID = null;
      }
    } catch (e) {
      Logger.debug('Could not get WiFi SSID: $e', tag: 'NetworkService');
      _currentWifiSSID = null;
    }
  }

  /// Update network status and notify listeners
  Future<void> _updateNetworkStatus(NetworkStatus newStatus) async {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _networkStatusController.add(newStatus);
      
      Logger.info(
        '📡 Network status changed: ${newStatus.name}',
        tag: 'NetworkService',
      );

      // Save network status to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_network_status', newStatus.name);
    }
  }

  /// Start periodic server discovery
  void _startServerDiscovery() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_localServerUrl == null) {
        await _checkLocalServer();
      } else {
        // Verify existing server is still reachable
        final isReachable = await _testServerConnection(_localServerUrl!);
        if (!isReachable) {
          _localServerUrl = null;
          await _clearSavedServerUrl();
          _localServerController.add(null);
          Logger.warning('❌ Lost connection to local server', tag: 'NetworkService');
          
          // Trigger full network check
          await _checkNetworkStatus();
        }
      }
    });
  }

  /// Save server URL to preferences
  Future<void> _saveServerUrl(String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_server_url', serverUrl);
    Logger.info('💾 Saved server URL: $serverUrl', tag: 'NetworkService');
  }

  /// Load saved server URL from preferences
  Future<void> _loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _localServerUrl = prefs.getString('local_server_url');
    if (_localServerUrl != null) {
      Logger.info('📂 Loaded saved server URL: $_localServerUrl', tag: 'NetworkService');
    }
  }

  /// Clear saved server URL
  Future<void> _clearSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_server_url');
    Logger.info('🗑️ Cleared saved server URL', tag: 'NetworkService');
  }

  /// Manually set server URL
  Future<bool> setServerUrl(String serverUrl) async {
    Logger.info('🔧 Manually setting server URL: $serverUrl', tag: 'NetworkService');
    
    final isReachable = await _testServerConnection(serverUrl);
    if (isReachable) {
      _localServerUrl = serverUrl;
      await _saveServerUrl(serverUrl);
      _localServerController.add(serverUrl);
      await _checkNetworkStatus();
      return true;
    }
    
    Logger.warning('❌ Manual server URL not reachable: $serverUrl', tag: 'NetworkService');
    return false;
  }

  /// Get server info
  Map<String, dynamic>? getServerInfo() {
    return _localServerInfo;
  }

  /// Force network check
  Future<void> forceNetworkCheck() async {
    Logger.info('🔄 Forcing network check...', tag: 'NetworkService');
    await _checkNetworkStatus();
  }

  /// Get preferred server type based on current network status
  ServerType getPreferredServerType() {
    switch (_currentStatus) {
      case NetworkStatus.offline:
        return ServerType.local; // Will use offline mode
      case NetworkStatus.wifiOnly:
      case NetworkStatus.full:
        return _localServerUrl != null ? ServerType.local : ServerType.cloud;
      case NetworkStatus.internetOnly:
        return ServerType.cloud;
    }
  }

  /// Get network status description
  String getNetworkStatusDescription() {
    switch (_currentStatus) {
      case NetworkStatus.offline:
        return 'No network connection';
      case NetworkStatus.wifiOnly:
        return 'WiFi connected, no internet';
      case NetworkStatus.internetOnly:
        return 'Internet connected, no local server';
      case NetworkStatus.full:
        return 'Full connectivity (WiFi + Internet + Local Server)';
    }
  }

  /// Get connection info summary
  Map<String, dynamic> getConnectionInfo() {
    return {
      'networkStatus': _currentStatus.name,
      'localServerUrl': _localServerUrl,
      'wifiSSID': _currentWifiSSID,
      'hasLocalServer': isConnectedToLocalServer,
      'hasInternet': hasInternetAccess,
      'hasWifi': hasWifiAccess,
      'preferredServerType': getPreferredServerType().name,
      'statusDescription': getNetworkStatusDescription(),
      'serverInfo': _localServerInfo,
      'lastServerCheck': _lastServerCheck?.toIso8601String(),
    };
  }
}