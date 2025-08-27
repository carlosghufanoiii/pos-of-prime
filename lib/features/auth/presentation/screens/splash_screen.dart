import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../providers/secure_auth_role_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // FAST SPLASH: Reduced animation time for quicker loading feel
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced from 2 seconds
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Faster curve
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9, // Start closer to final size
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Faster, less bouncy
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getStatusMessage(AuthRoleState state) {
    switch (state) {
      case AuthRoleState.initial:
        return 'Starting...';
      case AuthRoleState.loading:
        return 'Authenticating...';
      case AuthRoleState.roleResolving:
        return 'Verifying permissions...';
      case AuthRoleState.authenticated:
        return 'Welcome!';
      case AuthRoleState.unauthenticated:
        return 'Please login';
      case AuthRoleState.error:
        return 'Connection issue';
    }
  }

  IconData _getStatusIcon(AuthRoleState state) {
    switch (state) {
      case AuthRoleState.initial:
      case AuthRoleState.loading:
      case AuthRoleState.roleResolving:
        return Icons.sync;
      case AuthRoleState.authenticated:
        return Icons.check_circle;
      case AuthRoleState.unauthenticated:
        return Icons.login;
      case AuthRoleState.error:
        return Icons.warning;
    }
  }

  Color _getStatusColor(AuthRoleState state) {
    switch (state) {
      case AuthRoleState.initial:
      case AuthRoleState.loading:
      case AuthRoleState.roleResolving:
        return AppTheme.primaryColor;
      case AuthRoleState.authenticated:
        return Colors.green;
      case AuthRoleState.unauthenticated:
        return AppTheme.primaryColor;
      case AuthRoleState.error:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authData = ref.watch(secureAuthRoleProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.deepBlack, AppTheme.darkGrey, AppTheme.deepBlack],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE75480), // Prime Pink
                            Color(0xFFFF9540), // Prime Orange
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE75480).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF9540).withValues(alpha: 0.3),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'POS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Brand Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'PRIME',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8.0,
                          shadows: [
                            Shadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.8),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NIGHTCLUB POS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryColor,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Status Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Status Icon with Animation
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(authData.authState).withValues(alpha: 0.2),
                          border: Border.all(
                            color: _getStatusColor(authData.authState),
                            width: 2,
                          ),
                        ),
                        child: authData.authState == AuthRoleState.loading ||
                               authData.authState == AuthRoleState.roleResolving ||
                               authData.authState == AuthRoleState.initial
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Icon(
                                _getStatusIcon(authData.authState),
                                color: _getStatusColor(authData.authState),
                                size: 30,
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Status Text
                      Text(
                        _getStatusMessage(authData.authState),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // User info when authenticated
                      if (authData.user != null) ...[
                        Text(
                          'Welcome, ${authData.user!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            authData.user!.role.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],

                      // Error message
                      if (authData.hasError) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            authData.error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 100),

                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppConstants.brandTagline,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}