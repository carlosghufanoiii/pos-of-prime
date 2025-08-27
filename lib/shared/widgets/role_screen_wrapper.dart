import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../../features/auth/providers/firebase_auth_provider.dart';
import 'role_app_bar.dart';

/// Wrapper for role-specific screens that provides user context and common UI
class RoleScreenWrapper extends ConsumerWidget {
  final String title;
  final Widget child;
  final bool showBackButton;
  final List<Widget>? additionalActions;

  const RoleScreenWrapper({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseCurrentUserProvider);

    // If user is null, redirect to login
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: RoleAppBar(
        title: title,
        user: currentUser,
        showBackButton: showBackButton,
        additionalActions: additionalActions,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.deepBlack, AppTheme.darkGrey, AppTheme.deepBlack],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
