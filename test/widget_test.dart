import 'package:flutter_test/flutter_test.dart';
import 'package:prime_pos/shared/models/user_role.dart';

void main() {
  group('User Role Tests', () {
    test('User role permissions work correctly', () {
      // Test waiter permissions
      expect(UserRole.waiter.canCreateOrders, isTrue);
      expect(UserRole.waiter.canApproveOrders, isFalse);
      expect(UserRole.waiter.canManageUsers, isFalse);

      // Test admin permissions
      expect(UserRole.admin.canCreateOrders, isTrue);
      expect(UserRole.admin.canApproveOrders, isTrue);
      expect(UserRole.admin.canManageUsers, isTrue);
      
      // Test cashier permissions
      expect(UserRole.cashier.canApproveOrders, isTrue);
      expect(UserRole.cashier.canProcessPayments, isTrue);
    });
  });
  
  group('App Constants Tests', () {
    test('Currency constants are correct', () {
      const String currencySymbol = '₱';
      const String currencyCode = 'PHP';
      const double vatRate = 0.12;
      
      expect(currencySymbol, equals('₱'));
      expect(currencyCode, equals('PHP'));
      expect(vatRate, equals(0.12));
    });
  });
}
