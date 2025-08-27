// Flutter script to create the admin account first
// Run with: flutter run --target=create_admin_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/shared/services/firebase_service.dart';
import 'lib/shared/models/app_user.dart';
import 'lib/shared/models/user_role.dart';
import 'lib/shared/services/user_management_service.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AccountCreatorApp(),
    ),
  );
}

class AccountCreatorApp extends StatelessWidget {
  const AccountCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prime POS Account Creator',
      theme: ThemeData.dark(),
      home: const AccountCreatorScreen(),
    );
  }
}

class AccountCreatorScreen extends StatefulWidget {
  const AccountCreatorScreen({super.key});

  @override
  State<AccountCreatorScreen> createState() => _AccountCreatorScreenState();
}

class _AccountCreatorScreenState extends State<AccountCreatorScreen> {
  String _status = 'Ready to create accounts...';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await FirebaseService.initialize();
      setState(() {
        _status = '✅ Firebase initialized - Ready to create accounts!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase initialization failed: $e';
      });
    }
  }

  Future<void> _createOfficialAccounts() async {
    setState(() {
      _isCreating = true;
      _status = '🚀 Creating official accounts...';
    });

    final accounts = [
      {
        'email': 'admin@primepos.com',
        'password': 'Prime123!',
        'name': 'System Administrator',
        'role': UserRole.admin,
        'employeeId': 'ADMIN001'
      },
      {
        'email': 'waiter1@primepos.com',
        'password': 'Waiter123!',
        'name': 'Maria Santos',
        'role': UserRole.waiter,
        'employeeId': 'WAIT001'
      },
      {
        'email': 'waiter2@primepos.com',
        'password': 'Waiter123!',
        'name': 'Juan dela Cruz',
        'role': UserRole.waiter,
        'employeeId': 'WAIT002'
      },
      {
        'email': 'waiter3@primepos.com',
        'password': 'Waiter123!',
        'name': 'Ana Reyes',
        'role': UserRole.waiter,
        'employeeId': 'WAIT003'
      },
      {
        'email': 'kitchen@primepos.com',
        'password': 'Kitchen123!',
        'name': 'Chef Roberto',
        'role': UserRole.kitchen,
        'employeeId': 'KITCH001'
      },
      {
        'email': 'bartender@primepos.com',
        'password': 'Bartender123!',
        'name': 'Miguel Bar',
        'role': UserRole.bar,
        'employeeId': 'BART001'
      },
      {
        'email': 'cashier@primepos.com',
        'password': 'Cashier123!',
        'name': 'Elena Cash',
        'role': UserRole.cashier,
        'employeeId': 'CASH001'
      }
    ];

    int successCount = 0;
    List<String> errors = [];

    for (int i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      setState(() {
        _status = '📝 Creating ${account['role'].toString().split('.').last}: ${account['name']}...';
      });

      try {
        final user = AppUser(
          id: '', // Will be set by the service
          email: account['email'] as String,
          name: account['name'] as String,
          role: account['role'] as UserRole,
          employeeId: account['employeeId'] as String,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await UserManagementService.createUser(
          user,
          account['password'] as String,
        );

        if (success) {
          successCount++;
          print('✅ Created: ${account['email']}');
        } else {
          errors.add('Failed to create: ${account['email']}');
        }
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⚠️ Account already exists: ${account['email']}');
          successCount++; // Count as success since account exists
        } else {
          errors.add('Error creating ${account['email']}: $e');
          print('❌ Error: $e');
        }
      }

      // Small delay to avoid overwhelming Firebase
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isCreating = false;
      if (errors.isEmpty) {
        _status = '🎉 SUCCESS! Created $successCount accounts.\n\n'
            '👨‍💼 admin@primepos.com / Prime123!\n'
            '🍽️ waiter1-3@primepos.com / Waiter123!\n'
            '👨‍🍳 kitchen@primepos.com / Kitchen123!\n'
            '🍺 bartender@primepos.com / Bartender123!\n'
            '💰 cashier@primepos.com / Cashier123!\n\n'
            'All accounts are ready to use!';
      } else {
        _status = '⚠️ Created $successCount accounts with ${errors.length} errors:\n'
            '${errors.join('\n')}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Prime POS - Official Account Creator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createOfficialAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE75480),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: _isCreating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Creating Accounts...'),
                      ],
                    )
                  : const Text('🚀 Create All Official Accounts'),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create 7 production-ready accounts:\n'
              '• 1 Admin • 3 Waiters • 1 Kitchen • 1 Bartender • 1 Cashier',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}