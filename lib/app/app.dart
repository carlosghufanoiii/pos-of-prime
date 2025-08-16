import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/constants/app_theme.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/providers/appwrite_auth_provider.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';

class PrimePOSApp extends ConsumerWidget {
  const PrimePOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PRIME Nightclub POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Nightclub theme is always dark
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(appwriteCurrentUserProvider);
    
    if (currentUser == null) {
      return const LoginScreen();
    } else {
      return DashboardScreen(user: currentUser);
    }
  }
}