import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/product.dart';

// Current order state
class OrderState {
  final List<OrderItem> items;
  final String? tableNumber;
  final String? customerName;
  final String? notes;

  const OrderState({
    this.items = const [],
    this.tableNumber,
    this.customerName,
    this.notes,
  });

  OrderState copyWith({
    List<OrderItem>? items,
    String? tableNumber,
    String? customerName,
    String? notes,
  }) {
    return OrderState(
      items: items ?? this.items,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get taxAmount => subtotal * 0.12; // 12% VAT
  double get total => subtotal + taxAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

// Order state notifier
class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(const OrderState());

  void addItem(Product product, {int quantity = 1}) {
    final existingItemIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    List<OrderItem> updatedItems;
    if (existingItemIndex >= 0) {
      // Update existing item quantity
      updatedItems = List.from(state.items);
      final newQuantity = updatedItems[existingItemIndex].quantity + quantity;
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
        quantity: newQuantity,
        totalPrice: product.price * newQuantity,
      );
    } else {
      // Add new item
      final newItem = OrderItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        quantity: quantity,
        unitPrice: product.price,
        totalPrice: product.price * quantity,
      );
      updatedItems = [...state.items, newItem];
    }
    
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String itemId) {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity,
          totalPrice: item.unitPrice * quantity,
        );
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
  }

  void setTableNumber(String? tableNumber) {
    state = state.copyWith(tableNumber: tableNumber);
  }

  void setCustomerName(String? customerName) {
    state = state.copyWith(customerName: customerName);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void clearOrder() {
    state = const OrderState();
  }

  Order createOrder(String waiterId, String waiterName) {
    final timestamp = DateTime.now();
    final orderNumber = 'ORD-${timestamp.millisecondsSinceEpoch.toString().substring(8)}';
    
    return Order(
      id: 'order_${timestamp.millisecondsSinceEpoch}',
      orderNumber: orderNumber,
      waiterId: waiterId,
      waiterName: waiterName,
      tableNumber: state.tableNumber,
      customerName: state.customerName,
      items: state.items,
      status: OrderStatus.pendingApproval,
      createdAt: timestamp,
      subtotal: state.subtotal,
      taxAmount: state.taxAmount,
      total: state.total,
      notes: state.notes,
    );
  }
}

// Order state provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier();
});

// Quick access providers
final orderItemCountProvider = Provider<int>((ref) {
  return ref.watch(orderProvider).itemCount;
});

final orderTotalProvider = Provider<double>((ref) {
  return ref.watch(orderProvider).total;
});

final orderSubtotalProvider = Provider<double>((ref) {
  return ref.watch(orderProvider).subtotal;
});

final orderTaxProvider = Provider<double>((ref) {
  return ref.watch(orderProvider).taxAmount;
});