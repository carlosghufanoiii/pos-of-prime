import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  try {
    print('Creating admin account...');

    // Create user with email and password
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: 'admin@primepos.com',
      password: 'admin123',
    );

    final user = userCredential.user;
    if (user != null) {
      // Update display name
      await user.updateDisplayName('Prime POS Admin');

      // Create user profile in Firestore
      await firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': 'admin@primepos.com',
        'name': 'Prime POS Admin',
        'role': 'admin',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Admin account created successfully!');
      print('📧 Email: admin@primepos.com');
      print('🔑 Password: admin123');
      print('👤 Name: Prime POS Admin');
      print('🔐 Role: admin');
    }
  } catch (e) {
    print('❌ Error creating admin account: $e');

    // If user already exists, just update the profile
    if (e.toString().contains('email-already-in-use')) {
      print('User already exists. Trying to sign in and update profile...');

      try {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: 'admin@primepos.com',
          password: 'admin123',
        );

        final user = userCredential.user;
        if (user != null) {
          await firestore.collection('users').doc(user.uid).set({
            'id': user.uid,
            'email': 'admin@primepos.com',
            'name': 'Prime POS Admin',
            'role': 'admin',
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

          print('✅ Admin profile updated successfully!');
        }
      } catch (signInError) {
        print('❌ Sign in error: $signInError');
      }
    }
  }
}
