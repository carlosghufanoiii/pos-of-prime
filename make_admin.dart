import 'lib/shared/services/firebase_database_service.dart';
import 'lib/shared/services/firebase_service.dart';
import 'lib/shared/models/user_role.dart';

/// Script to make a specific user admin
void main() async {
  print('🔐 Prime POS - Make User Admin');
  print('=' * 40);
  
  try {
    // Initialize Firebase
    await FirebaseService.ensureInitialized();
    final dbService = FirebaseDatabaseService();
    
    // Email to make admin
    const adminEmail = 'admin@primepos.com';
    
    print('🔍 Searching for user: $adminEmail');
    
    // Get all users
    final users = await dbService.getAllUsers();
    print('📋 Found ${users.length} total users');
    
    // Find user by email
    final targetUser = users.where((user) => user.email == adminEmail).firstOrNull;
    
    if (targetUser == null) {
      print('❌ User not found: $adminEmail');
      print('📝 Available users:');
      for (var user in users) {
        print('   • ${user.email} (${user.role.name}) - ID: ${user.id}');
      }
      return;
    }
    
    print('👤 Found user: ${targetUser.name}');
    print('   Email: ${targetUser.email}');
    print('   Current Role: ${targetUser.role.name}');
    print('   Active: ${targetUser.isActive}');
    print('   ID: ${targetUser.id}');
    
    if (targetUser.role == UserRole.admin) {
      print('✅ User is already admin!');
      return;
    }
    
    print('🔧 Updating user to admin role...');
    
    // Update user to admin
    final updatedUser = targetUser.copyWith(
      role: UserRole.admin,
      updatedAt: DateTime.now(),
    );
    
    await dbService.updateUser(updatedUser);
    
    print('✅ Successfully updated user to admin!');
    print('🎯 User $adminEmail now has full admin access');
    print('');
    print('📱 You can now:');
    print('   • Access admin panel');
    print('   • Create/manage users');  
    print('   • Assign roles properly');
    print('   • Manage menu items');
    print('');
    print('🔄 Please refresh the app or log out and log back in');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}