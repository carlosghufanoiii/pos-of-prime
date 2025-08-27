import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';
import 'lib/shared/services/firebase_database_service.dart';
import 'lib/shared/models/app_user.dart';
import 'lib/shared/models/user_role.dart';

void main() async {
  print('🚀 Creating Official Prime POS Accounts...');
  print('==========================================');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    final auth = FirebaseAuth.instance;
    final dbService = FirebaseDatabaseService();

    // Official accounts to create
    final accounts = [
      // Admin Account
      {
        'email': 'admin@primepos.com',
        'password': 'Prime123!',
        'name': 'System Administrator',
        'role': UserRole.admin,
        'employeeId': 'ADMIN001',
      },
      
      // Waiters
      {
        'email': 'waiter1@primepos.com',
        'password': 'Waiter123!',
        'name': 'Maria Santos',
        'role': UserRole.waiter,
        'employeeId': 'WAIT001',
      },
      {
        'email': 'waiter2@primepos.com',
        'password': 'Waiter123!',
        'name': 'Juan dela Cruz',
        'role': UserRole.waiter,
        'employeeId': 'WAIT002',
      },
      {
        'email': 'waiter3@primepos.com',
        'password': 'Waiter123!',
        'name': 'Ana Reyes',
        'role': UserRole.waiter,
        'employeeId': 'WAIT003',
      },
      
      // Kitchen Staff
      {
        'email': 'kitchen@primepos.com',
        'password': 'Kitchen123!',
        'name': 'Chef Roberto',
        'role': UserRole.kitchen,
        'employeeId': 'KITCH001',
      },
      
      // Bartender
      {
        'email': 'bartender@primepos.com',
        'password': 'Bartender123!',
        'name': 'Miguel Bar',
        'role': UserRole.bar,
        'employeeId': 'BART001',
      },
      
      // Cashier
      {
        'email': 'cashier@primepos.com',
        'password': 'Cashier123!',
        'name': 'Elena Cash',
        'role': UserRole.cashier,
        'employeeId': 'CASH001',
      },
    ];

    print('\n📝 Creating ${accounts.length} official accounts...\n');

    for (int i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      try {
        print('${i + 1}. Creating ${account['role'].toString().split('.').last.toUpperCase()}: ${account['name']}');
        
        // Create Firebase Auth account
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: account['email'] as String,
          password: account['password'] as String,
        );

        if (userCredential.user != null) {
          // Update display name
          await userCredential.user!.updateDisplayName(account['name'] as String);
          
          // Create user in Firestore
          final appUser = AppUser(
            id: userCredential.user!.uid,
            email: account['email'] as String,
            name: account['name'] as String,
            role: account['role'] as UserRole,
            employeeId: account['employeeId'] as String,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await dbService.createUser(appUser);
          
          print('   ✅ Account created successfully');
          print('   📧 Email: ${account['email']}');
          print('   🔐 Password: ${account['password']}');
          print('   👤 Employee ID: ${account['employeeId']}');
          print('   🎯 Role: ${account['role'].toString().split('.').last}');
          print('');
        }
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('   ⚠️  Account already exists: ${account['email']}');
          print('   🔐 Password: ${account['password']}');
          print('');
        } else {
          print('   ❌ Failed to create account: $e');
          print('');
        }
      }
    }

    print('🎉 Official Account Creation Complete!');
    print('=====================================');
    print('');
    print('📋 SUMMARY OF ACCOUNTS:');
    print('');
    print('👨‍💼 ADMIN:');
    print('   admin@primepos.com / Prime123!');
    print('');
    print('🍽️ WAITERS:');
    print('   waiter1@primepos.com / Waiter123! (Maria Santos)');
    print('   waiter2@primepos.com / Waiter123! (Juan dela Cruz)');
    print('   waiter3@primepos.com / Waiter123! (Ana Reyes)');
    print('');
    print('👨‍🍳 KITCHEN:');
    print('   kitchen@primepos.com / Kitchen123! (Chef Roberto)');
    print('');
    print('🍺 BARTENDER:');
    print('   bartender@primepos.com / Bartender123! (Miguel Bar)');
    print('');
    print('💰 CASHIER:');
    print('   cashier@primepos.com / Cashier123! (Elena Cash)');
    print('');
    print('🔧 All accounts are now active and ready to use!');
    print('🏪 Admin can view all users in the User Management section.');

  } catch (e) {
    print('❌ Error: $e');
  }
}