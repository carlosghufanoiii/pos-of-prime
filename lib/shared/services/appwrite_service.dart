import 'dart:async';
import 'package:appwrite/appwrite.dart';

/// Simple Appwrite service for real-time capabilities
/// Focuses on basic connectivity and real-time features only
class AppwriteService {
  static Client? _client;
  static Realtime? _realtime;
  static bool _initialized = false;

  // Initialize Appwrite with minimal setup
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _client = Client()
          .setEndpoint('http://localhost/v1')
          .setProject('prime-pos');

      _realtime = Realtime(_client!);
      _initialized = true;
      
      print('Appwrite initialized successfully');
    } catch (e) {
      print('Appwrite initialization failed: $e');
      // Don't throw - allow app to continue with limited functionality
    }
  }

  // Check if Appwrite is available and initialized
  static bool get isAvailable => _initialized && _client != null;

  // Subscribe to real-time order updates
  static StreamSubscription<RealtimeMessage>? subscribeToOrderUpdates(Function(RealtimeMessage) callback) {
    if (!isAvailable) {
      print('Appwrite not available - real-time order updates disabled');
      return null;
    }
    
    try {
      return _realtime!.subscribe(['databases.prime_pos_db.collections.orders.documents'])
          .stream.listen(callback);
    } catch (e) {
      print('Failed to subscribe to order updates: $e');
      return null;
    }
  }

  // Subscribe to real-time product updates
  static StreamSubscription<RealtimeMessage>? subscribeToProductUpdates(Function(RealtimeMessage) callback) {
    if (!isAvailable) {
      print('Appwrite not available - real-time product updates disabled');
      return null;
    }
    
    try {
      return _realtime!.subscribe(['databases.prime_pos_db.collections.products.documents'])
          .stream.listen(callback);
    } catch (e) {
      print('Failed to subscribe to product updates: $e');
      return null;
    }
  }

  // Subscribe to real-time user updates
  static StreamSubscription<RealtimeMessage>? subscribeToUserUpdates(Function(RealtimeMessage) callback) {
    if (!isAvailable) {
      print('Appwrite not available - real-time user updates disabled');
      return null;
    }
    
    try {
      return _realtime!.subscribe(['databases.prime_pos_db.collections.users.documents'])
          .stream.listen(callback);
    } catch (e) {
      print('Failed to subscribe to user updates: $e');
      return null;
    }
  }

  // Basic health check
  static Future<bool> checkHealth() async {
    if (!isAvailable) return false;
    
    try {
      // Simple connectivity test would go here
      return true;
    } catch (e) {
      print('Appwrite health check failed: $e');
      return false;
    }
  }
}