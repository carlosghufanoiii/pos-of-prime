import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prime_pos/shared/utils/logger.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/services/network_service.dart';
import '../../providers/secure_auth_role_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Enhanced state management
  bool _isFormValid = false;
  // Current auth step tracking - can be re-added when needed
  int _retryCount = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  // Removed pulse controller
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Network status
  NetworkStatus _networkStatus = NetworkStatus.offline;

  // Focus nodes for accessibility
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _loginButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNetworkMonitoring();
    _setupFormValidation();
    _preloadDemoCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    // Removed pulse controller
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Removed pulse controller initialization

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    // Removed pulse animation

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    // Removed pulse controller start
  }

  void _initializeNetworkMonitoring() {
    // Initialize network service
    NetworkService.instance.initialize();

    // Listen to network status changes
    NetworkService.instance.networkStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _networkStatus = status;
        });
      }
    });

    // Get initial network status
    _networkStatus = NetworkService.instance.currentStatus;
  }

  void _setupFormValidation() {
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isValid =
        email.isNotEmpty &&
        password.isNotEmpty &&
        _validateEmail(email) == null &&
        _validatePassword(password) == null;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
        // Form validation updated
      });
    }
  }

  void _preloadDemoCredentials() {
    // Add subtle hint animation for demo credentials
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _emailController.text.isEmpty) {
        _showDemoHint();
      }
    });
  }

  void _showDemoHint() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Tip: Try demo@waiter.com or demo@admin.com'),
          ],
        ),
        backgroundColor: AppTheme.surfaceGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Reset retry count on new attempt
    _retryCount = 0;

    await _performLoginWithRetry(email, password);
  }

  Future<void> _performLoginWithRetry(String email, String password) async {
    try {
      Logger.info(
        'Attempting login for: $email (attempt ${_retryCount + 1})',
        tag: 'LoginScreen',
      );

      // Update current step for better user feedback
      // Connecting to server...

      // Check network status first
      await NetworkService.instance.forceNetworkCheck();
      final networkStatus = NetworkService.instance.currentStatus;

      if (networkStatus == NetworkStatus.offline) {
        throw Exception(
          'No network connection. Please check your internet connection.',
        );
      }

      // Authenticating user...

      // Progressive timeout based on network conditions
      final timeoutDuration = _getTimeoutForNetworkStatus(networkStatus);

      await ref
          .read(secureAuthRoleProvider.notifier)
          .signInWithEmailPassword(email, password)
          .timeout(
            timeoutDuration,
            onTimeout: () {
              throw Exception(
                'Login request timed out after ${timeoutDuration.inSeconds}s. ${_getRetryMessage()}',
              );
            },
          );

      // Authentication successful!

      // Success haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      Logger.error(
        'Login attempt ${_retryCount + 1} failed',
        error: e,
        tag: 'LoginScreen',
      );

      // Clear auth status

      // Handle specific error types
      await _handleLoginError(e, email, password);
    }
  }

  Duration _getTimeoutForNetworkStatus(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.full:
        return const Duration(seconds: 15);
      case NetworkStatus.internetOnly:
        return const Duration(seconds: 25);
      case NetworkStatus.wifiOnly:
        return const Duration(seconds: 35);
      case NetworkStatus.offline:
        return const Duration(seconds: 10);
    }
  }

  String _getRetryMessage() {
    final networkDesc = NetworkService.instance.getNetworkStatusDescription();
    return 'Network: $networkDesc. Tap to retry.';
  }

  Future<void> _handleLoginError(
    dynamic error,
    String email,
    String password,
  ) async {
    final errorMessage = error.toString().replaceAll('Exception: ', '');

    // Determine if error is retryable
    final isRetryableError = _isRetryableError(errorMessage);

    if (isRetryableError && _retryCount < 2) {
      _retryCount++;

      // Show retry dialog
      final shouldRetry = await _showRetryDialog(
        'Connection Issue',
        errorMessage,
        _retryCount,
      );

      if (shouldRetry) {
        // Wait a bit before retry
        await Future.delayed(Duration(seconds: _retryCount * 2));
        await _performLoginWithRetry(email, password);
        return;
      }
    }

    // Show error to user
    _showErrorFeedback(errorMessage, isRetryableError && _retryCount < 2);
  }

  bool _isRetryableError(String errorMessage) {
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      'unreachable',
      'failed to connect',
      'temporary',
    ];

    return retryableErrors.any(
      (error) => errorMessage.toLowerCase().contains(error),
    );
  }

  Future<bool> _showRetryDialog(
    String title,
    String message,
    int attempt,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.refresh, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attempt $attempt of 3',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildNetworkStatusChip(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorFeedback(String message, bool canRetry) {
    // Error haptic feedback
    HapticFeedback.mediumImpact();

    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Login Failed',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 14)),
          if (canRetry) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the login button to try again',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: AppTheme.surfaceGrey,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: canRetry ? 6 : 4),
      action: canRetry
          ? SnackBarAction(
              label: 'Retry',
              onPressed: _handleEmailLogin,
              textColor: AppTheme.primaryColor,
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  // Google login functionality removed for simplicity
  // Can be re-added when Google Sign-In is implemented in UI

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  Widget _buildNetworkStatusChip() {
    final status = NetworkService.instance.currentStatus;
    final description = NetworkService.instance.getNetworkStatusDescription();
    
    Color chipColor;
    IconData chipIcon;
    
    switch (status) {
      case NetworkStatus.offline:
        chipColor = AppTheme.errorColor;
        chipIcon = Icons.wifi_off;
        break;
      case NetworkStatus.wifiOnly:
        chipColor = AppTheme.warningColor;
        chipIcon = Icons.wifi;
        break;
      case NetworkStatus.internetOnly:
        chipColor = Colors.blue;
        chipIcon = Icons.cloud;
        break;
      case NetworkStatus.full:
        chipColor = AppTheme.successColor;
        chipIcon = Icons.cloud_done;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Progressive loading indicator - can be re-added to UI when needed
  
  // Demo credentials auto-fill - can be re-added when demo UI is implemented

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthRoleData>(secureAuthRoleProvider, (previous, next) {
      if (next.hasError) {
        _showErrorSnackBar(next.error!);
        ref.read(secureAuthRoleProvider.notifier).clearError();
      }
    });

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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive padding based on screen size
                    final isTablet = constraints.maxWidth > 600;
                    final isLargeScreen = constraints.maxWidth > 900;
                    final horizontalPadding = isLargeScreen
                        ? 64.0
                        : isTablet
                        ? 48.0
                        : 32.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : double.infinity,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Prime POS Logo with Modern Design
                            Container(
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
                                    color: const Color(
                                      0xFFE75480,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF9540,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Diamond icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.diamond_outlined,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // POS text
                                  const Text(
                                    'POS',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Brand Text with Modern Typography
                            Text(
                              'PRIME',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8.0,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.8,
                                    ),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 4.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 120,
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
                            const SizedBox(height: 32),

                            // Demo credentials info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Demo Credentials',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Admin: demo@admin.com / demo123',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Waiter: demo@waiter.com / demo123',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Bartender: demo@bar.com / demo123',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Kitchen: demo@kitchen.com / demo123',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Cashier: demo@cashier.com / demo123',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Network Status Indicator (only show if not optimal)
                            if (_networkStatus != NetworkStatus.full)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildNetworkStatusChip(),
                              ),

                            const SizedBox(height: 8),

                            // Modern Login Card with Glass Effect
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceGrey.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width > 600
                                        ? 40
                                        : 32,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        Text(
                                          'ACCESS PORTAL',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Modern Email Field
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: _validateEmail,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Email Address',
                                              prefixIcon: Icon(
                                                Icons.email_outlined,
                                                color: AppTheme.primaryColor,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.all(20),
                                              labelStyle: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Modern Password Field
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            validator: _validatePassword,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              prefixIcon: Icon(
                                                Icons.lock_outlined,
                                                color: AppTheme.primaryColor,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.all(20),
                                              labelStyle: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Modern Login Button with Gradient
                                        Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryColor,
                                                AppTheme.primaryDark,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: authData.isLoading
                                                ? null
                                                : _handleEmailLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: authData.isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 3,
                                                        ),
                                                  )
                                                : Text(
                                                    'ENTER PRIME',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 2.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Footer
                            Text(
                              AppConstants.brandTagline,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
