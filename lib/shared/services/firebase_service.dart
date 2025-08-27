import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static GoogleSignIn? _googleSignIn;
  static bool _initialized = false;
  static bool _initializing = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      // Quick wait for ongoing initialization
      int attempts = 0;
      while (_initializing && !_initialized && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return;
    }

    _initializing = true;
    try {
      // FAST INIT: Check if Firebase is already initialized
      try {
        Firebase.app(); // This will throw if no default app exists
        Logger.info('⚡ Firebase already initialized, using existing app', tag: 'FirebaseService');
      } catch (e) {
        // FAST INIT: Initialize with minimal configuration
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
        Logger.info('⚡ Firebase initialized quickly', tag: 'FirebaseService');
      }

      // Get instances immediately
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _googleSignIn = GoogleSignIn();
      
      _initialized = true;
      Logger.info('⚡ Firebase services ready', tag: 'FirebaseService');

      // BACKGROUND: Configure Firestore settings after initialization
      _configureFirestoreInBackground();

    } catch (e) {
      Logger.error('⚠️ Firebase initialization failed: $e', error: e, tag: 'FirebaseService');
      
      // Mark as failed but don't block app
      _initialized = false;
      throw Exception('Firebase initialization failed: $e');
    } finally {
      _initializing = false;
    }
  }

  static void _configureFirestoreInBackground() {
    // Configure Firestore settings in background (non-blocking)
    Future(() async {
      try {
        _firestore?.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        Logger.info('⚡ Firestore configured in background', tag: 'FirebaseService');
      } catch (e) {
        Logger.warning('Background Firestore config failed, continuing', tag: 'FirebaseService');
      }
    });
  }

  static bool get isInitialized => _initialized;
  
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw StateError('Firebase Auth not initialized. Call FirebaseService.initialize() first.');
    }
    return _auth!;
  }
  
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('Firebase Firestore not initialized. Call FirebaseService.initialize() first.');
    }
    return _firestore!;
  }
  
  static GoogleSignIn get googleSignIn {
    if (_googleSignIn == null) {
      throw StateError('Google Sign In not initialized. Call FirebaseService.initialize() first.');
    }
    return _googleSignIn!;
  }

  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    } else {
      // Even if marked as initialized, verify Firebase is actually available
      try {
        Firebase.app(); // Verify default app exists
      } catch (e) {
        Logger.warning('Firebase app not found despite being marked initialized, re-initializing', tag: 'FirebaseService');
        _initialized = false;
        await initialize();
      }
    }
  }
}
