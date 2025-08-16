import 'product.dart';

enum OrderStatus {
  pendingApproval('Pending Approval'),
  approved('Approved'),
  inPrep('In Preparation'),
  ready('Ready'),
  served('Served'),
  cancelled('Cancelled'),
  voided('Voided');

  const OrderStatus(this.displayName);
  final String displayName;
}

enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  eWallet('E-Wallet');

  const PaymentMethod(this.displayName);
  final String displayName;
}

class Order {
  final String id;
  final String orderNumber;
  final String? tableNumber;
  final String? customerName;
  final List<OrderItem> items;
  final OrderStatus status;
  final String waiterId;
  final String waiterName;
  final String? cashierId;
  final String? cashierName;
  final double subtotal;
  final double taxAmount;
  final double serviceCharge;
  final double discount;
  final double total;
  final PaymentMethod? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final DateTime? prepStartedAt;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final String? notes;

  Order({
    required this.id,
    required this.orderNumber,
    this.tableNumber,
    this.customerName,
    required this.items,
    required this.status,
    required this.waiterId,
    required this.waiterName,
    this.cashierId,
    this.cashierName,
    required this.subtotal,
    this.taxAmount = 0,
    this.serviceCharge = 0,
    this.discount = 0,
    required this.total,
    this.paymentMethod,
    required this.createdAt,
    DateTime? updatedAt,
    this.approvedAt,
    this.prepStartedAt,
    this.readyAt,
    this.servedAt,
    this.notes,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isAlcoholicOrder => items.any((item) => item.product.isAlcoholic);
  bool get hasNonAlcoholicItems => items.any((item) => !item.product.isAlcoholic);
  
  List<OrderItem> get alcoholicItems => 
      items.where((item) => item.product.isAlcoholic).toList();
  
  List<OrderItem> get nonAlcoholicItems => 
      items.where((item) => !item.product.isAlcoholic).toList();

  Order copyWith({
    String? id,
    String? orderNumber,
    String? tableNumber,
    String? customerName,
    List<OrderItem>? items,
    OrderStatus? status,
    String? waiterId,
    String? waiterName,
    String? cashierId,
    String? cashierName,
    double? subtotal,
    double? taxAmount,
    double? serviceCharge,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? prepStartedAt,
    DateTime? readyAt,
    DateTime? servedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      status: status ?? this.status,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      approvedAt: approvedAt ?? this.approvedAt,
      prepStartedAt: prepStartedAt ?? this.prepStartedAt,
      readyAt: readyAt ?? this.readyAt,
      servedAt: servedAt ?? this.servedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.name,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'serviceCharge': serviceCharge,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod?.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'prepStartedAt': prepStartedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'servedAt': servedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      tableNumber: json['tableNumber'] as String?,
      customerName: json['customerName'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere((s) => s.name == json['status']),
      waiterId: json['waiterId'] as String,
      waiterName: json['waiterName'] as String,
      cashierId: json['cashierId'] as String?,
      cashierName: json['cashierName'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere((p) => p.name == json['paymentMethod'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      prepStartedAt: json['prepStartedAt'] != null
          ? DateTime.parse(json['prepStartedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.parse(json['readyAt'] as String)
          : null,
      servedAt: json['servedAt'] != null
          ? DateTime.parse(json['servedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final List<ProductModifier> selectedModifiers;
  final String? notes;
  final double unitPrice;
  final double totalPrice;
  final OrderStatus status;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedModifiers = const [],
    this.notes,
    required this.unitPrice,
    required this.totalPrice,
    this.status = OrderStatus.pendingApproval,
  });

  OrderItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<ProductModifier>? selectedModifiers,
    String? notes,
    double? unitPrice,
    double? totalPrice,
    OrderStatus? status,
  }) {
    return OrderItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
      'notes': notes,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'status': status.name,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      selectedModifiers: (json['selectedModifiers'] as List<dynamic>?)
          ?.map((m) => ProductModifier.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      notes: json['notes'] as String?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: OrderStatus.values.firstWhere((s) => s.name == json['status']),
    );
  }
}