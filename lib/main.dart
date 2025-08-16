import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/app.dart';
import 'shared/services/appwrite_service.dart';
import 'shared/services/appwrite_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize Appwrite services
  await AppwriteService.initialize();
  await AppwriteDatabaseService.initialize();
  
  runApp(
    const ProviderScope(
      child: PrimePOSApp(),
    ),
  );
}