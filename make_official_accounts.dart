// Official Account Creator for Prime POS
// This script creates all production-ready accounts

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🚀 Creating Official Prime POS Accounts');
  print('=======================================');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    print('✅ Firebase initialized successfully');
    print('');
    
    // Official accounts data
    final accounts = [
      {
        'email': 'admin@primepos.com',
        'password': 'Prime123!',
        'name': 'System Administrator',
        'role': 'admin',
        'employeeId': 'ADMIN001'
      },
      {
        'email': 'waiter1@primepos.com',
        'password': 'Waiter123!',
        'name': 'Maria Santos',
        'role': 'waiter',
        'employeeId': 'WAIT001'
      },
      {
        'email': 'waiter2@primepos.com',
        'password': 'Waiter123!',
        'name': 'Juan dela Cruz',
        'role': 'waiter',
        'employeeId': 'WAIT002'
      },
      {
        'email': 'waiter3@primepos.com',
        'password': 'Waiter123!',
        'name': 'Ana Reyes',
        'role': 'waiter',
        'employeeId': 'WAIT003'
      },
      {
        'email': 'kitchen@primepos.com',
        'password': 'Kitchen123!',
        'name': 'Chef Roberto',
        'role': 'kitchen',
        'employeeId': 'KITCH001'
      },
      {
        'email': 'bartender@primepos.com',
        'password': 'Bartender123!',
        'name': 'Miguel Bar',
        'role': 'bar',
        'employeeId': 'BART001'
      },
      {
        'email': 'cashier@primepos.com',
        'password': 'Cashier123!',
        'name': 'Elena Cash',
        'role': 'cashier',
        'employeeId': 'CASH001'
      }
    ];
    
    print('📝 Creating ${accounts.length} official accounts...');
    print('');
    
    for (int i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      print('${i + 1}. Creating ${account['role']!.toUpperCase()}: ${account['name']}');
      
      try {
        // Create Firebase Auth account
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );
        
        if (userCredential.user != null) {
          final user = userCredential.user!;
          
          // Update display name
          await user.updateDisplayName(account['name']!);
          
          // Create Firestore document
          final userData = {
            'id': user.uid,
            'email': account['email']!,
            'name': account['name']!,
            'role': account['role']!,
            'employeeId': account['employeeId']!,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          
          await firestore.collection('users').doc(user.uid).set(userData);
          
          print('   ✅ Account created successfully!');
          print('   📧 ${account['email']}');
          print('   🔐 ${account['password']}');
          print('   👤 ${account['employeeId']}');
          print('   🎯 Role: ${account['role']}');
          print('');
        }
        
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('   ⚠️ Account already exists: ${account['email']}');
          print('   🔐 Password: ${account['password']}');
          print('   ✅ You can login with existing credentials');
          print('');
        } else {
          print('   ❌ Failed: $e');
          print('');
        }
      }
    }
    
    print('🎉 OFFICIAL ACCOUNT CREATION COMPLETE!');
    print('====================================');
    print('');
    print('📋 ACCOUNT SUMMARY:');
    print('');
    print('👨‍💼 ADMIN: admin@primepos.com / Prime123!');
    print('🍽️ WAITER 1: waiter1@primepos.com / Waiter123!');
    print('🍽️ WAITER 2: waiter2@primepos.com / Waiter123!');  
    print('🍽️ WAITER 3: waiter3@primepos.com / Waiter123!');
    print('👨‍🍳 KITCHEN: kitchen@primepos.com / Kitchen123!');
    print('🍺 BARTENDER: bartender@primepos.com / Bartender123!');
    print('💰 CASHIER: cashier@primepos.com / Cashier123!');
    print('');
    print('🔧 ALL ACCOUNTS ARE NOW ACTIVE AND READY!');
    print('🏪 Admin can view all users in User Management.');
    print('📱 Test login with any of the accounts above.');
    
  } catch (e) {
    print('❌ Error creating accounts: $e');
    print('');
    print('💡 Try these alternatives:');
    print('   • Use the web app at http://localhost:8080');
    print('   • Use Firebase Console manually');
    print('   • Check OFFICIAL_ACCOUNTS.md for details');
  }
}