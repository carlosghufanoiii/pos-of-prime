enum UserRole {
  waiter('Waiter'),
  cashier('Cashier'),
  kitchen('Kitchen'),
  bartender('Bartender'),
  admin('Admin');

  const UserRole(this.displayName);
  
  final String displayName;

  // Permissions
  bool get canCreateOrders => this == UserRole.waiter || this == UserRole.admin;
  bool get canApproveOrders => this == UserRole.cashier || this == UserRole.admin;
  bool get canViewKitchenQueue => this == UserRole.kitchen || this == UserRole.admin;
  bool get canViewBarQueue => this == UserRole.bartender || this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
  bool get canManageProducts => this == UserRole.admin;
  bool get canManageInventory => this == UserRole.admin;
  bool get canViewReports => this == UserRole.admin || this == UserRole.cashier;
  bool get canProcessPayments => this == UserRole.cashier || this == UserRole.admin;
  bool get canVoidOrders => this == UserRole.cashier || this == UserRole.admin;
}