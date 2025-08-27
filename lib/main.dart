import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/app.dart';
import 'shared/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start app immediately with minimal initialization
  runApp(const ProviderScope(child: PrimePOSApp()));

  // Initialize heavy services in background after app starts
  _initializeServicesInBackground();
}

void _initializeServicesInBackground() async {
  try {
    // Initialize lightweight services first
    tz.initializeTimeZones();
    
    // Initialize Hive in background
    Hive.initFlutter().catchError((e) {
      print('⚠️ Hive initialization delayed: $e');
    });

    // Initialize Firebase with low priority
    FirebaseService.initialize().catchError((e) {
      print('⚠️ Firebase initialization delayed: $e');
    });
  } catch (e) {
    print('⚠️ Background initialization error: $e');
  }
}
