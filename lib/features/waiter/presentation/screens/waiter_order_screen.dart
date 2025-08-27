import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/waiter_provider.dart';
import '../../data/waiter_service.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/services/order_service.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../features/auth/providers/firebase_auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/cart_summary.dart';
import '../widgets/order_confirmation_sheet.dart';

class WaiterOrderScreen extends ConsumerStatefulWidget {
  const WaiterOrderScreen({super.key});

  @override
  ConsumerState<WaiterOrderScreen> createState() => _WaiterOrderScreenState();
}

class _WaiterOrderScreenState extends ConsumerState<WaiterOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _tableController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(orderItemCountProvider);
    final orderTotal = ref.watch(orderTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Cart'),
            Tab(text: 'Ready Orders', icon: Icon(Icons.room_service)),
          ],
        ),
        actions: [
          if (itemCount > 0)
            IconButton(
              onPressed: _showOrderConfirmation,
              icon: Badge(
                label: Text('$itemCount'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildCartTab(),
          _buildReadyOrdersTab(),
        ],
      ),
      bottomNavigationBar: itemCount > 0
          ? Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGrey.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$itemCount item${itemCount != 1 ? 's' : ''}'
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(orderTotal),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _showOrderConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'REVIEW ORDER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),

        // Category filters
        _buildCategoryFilters(),

        // Products grid
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      data: (categories) => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            CategoryChip(
              label: 'All',
              isSelected: selectedCategory == null,
              onPressed: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(searchQueryProvider.notifier).state = '';
                _searchController.clear();
              },
            ),
            ...categories.map(
              (category) => CategoryChip(
                label: category,
                isSelected: selectedCategory == category,
                onPressed: () {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  ref.read(searchQueryProvider.notifier).state = '';
                  _searchController.clear();
                },
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox(height: 50),
    );
  }

  Widget _buildProductGrid() {
    final productsAsync = ref.watch(filteredProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final orderState = ref.watch(orderProvider);
            final quantityInCart = orderState.items
                .where((item) => item.product.id == product.id)
                .fold(0, (sum, item) => sum + item.quantity);
                
            return ProductCard(
              product: product,
              quantityInCart: quantityInCart,
              onAddToCart: () => _addProductToCart(product),
              onIncreaseQuantity: () => _addProductToCart(product),
              onDecreaseQuantity: () => _decreaseProductQuantity(product),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCartTab() {
    final orderState = ref.watch(orderProvider);

    if (orderState.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your cart is empty'),
            Text('Add items from the Products tab'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Order details form
        _buildOrderDetailsForm(),

        // Cart items
        Expanded(
          child: ListView.builder(
            itemCount: orderState.items.length,
            itemBuilder: (context, index) {
              final item = orderState.items[index];
              return _buildCartItem(item);
            },
          ),
        ),

        // Cart summary
        CartSummary(orderState: orderState),
      ],
    );
  }

  Widget _buildOrderDetailsForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceGrey.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Section Header
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ORDER DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Table Number Field
              TextField(
                controller: _tableController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Table Number',
                  labelStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.table_restaurant,
                    color: AppTheme.primaryColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.deepBlack.withValues(alpha: 0.3),
                ),
                onChanged: (value) {
                  ref
                      .read(orderProvider.notifier)
                      .setTableNumber(value.isEmpty ? null : value);
                },
              ),

              const SizedBox(height: 16),

              // Customer Name Field
              TextField(
                controller: _customerController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  labelStyle: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppTheme.deepBlack.withValues(alpha: 0.3),
                ),
                onChanged: (value) {
                  ref
                      .read(orderProvider.notifier)
                      .setCustomerName(value.isEmpty ? null : value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceGrey.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(item.unitPrice),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.product.isAlcoholic)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warningColor.withValues(alpha: 0.2),
                              AppTheme.warningColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'ALCOHOLIC',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Quantity controls and total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Total price
                  Text(
                    CurrencyFormatter.format(item.totalPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (item.quantity > 1) {
                              ref
                                  .read(orderProvider.notifier)
                                  .updateItemQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  );
                            } else {
                              ref
                                  .read(orderProvider.notifier)
                                  .removeItem(item.id);
                            }
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(orderProvider.notifier)
                                .updateItemQuantity(item.id, item.quantity + 1);
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProductToCart(Product product) {
    ref.read(orderProvider.notifier).addItem(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _decreaseProductQuantity(Product product) {
    final orderState = ref.read(orderProvider);
    final existingItem = orderState.items.firstWhere(
      (item) => item.product.id == product.id,
    );
    
    if (existingItem.quantity > 1) {
      ref.read(orderProvider.notifier).updateItemQuantity(
        existingItem.id, 
        existingItem.quantity - 1,
      );
    } else {
      ref.read(orderProvider.notifier).removeItem(existingItem.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} removed from cart'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showOrderConfirmation() {
    final orderState = ref.read(orderProvider);
    final currentUser = ref.read(firebaseCurrentUserProvider);

    if (orderState.items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderConfirmationSheet(
        orderState: orderState,
        onConfirm: () async {
          if (currentUser != null) {
            // Store context and navigator for safe async usage
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              // Create the order object
              final order = ref
                  .read(orderProvider.notifier)
                  .createOrder(currentUser.id, currentUser.name);

              // Save the order to the shared repository
              final success = await OrderService.createOrder(order);

              if (success) {
                // Clear the cart after successful order creation
                ref.read(orderProvider.notifier).clearOrder();

                if (mounted) {
                  navigator.pop(); // Close the bottom sheet
                  navigator.pop(); // Go back to dashboard

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Order ${order.orderNumber} Submitted!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Sent to kitchen/bar for preparation',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } else {
                throw Exception('Failed to create order');
              }
            } catch (e) {
              if (mounted) {
                navigator.pop(); // Close the bottom sheet

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to create order: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildReadyOrdersTab() {
    final currentUser = ref.watch(firebaseCurrentUserProvider);
    final readyOrdersAsync = ref.watch(waiterReadyOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(waiterReadyOrdersProvider.future),
      child: readyOrdersAsync.when(
        data: (orders) {
          // Filter orders for current waiter or show all if needed
          final waiterOrders = orders
              .where((order) => order.waiterId == currentUser?.id)
              .toList();

          if (waiterOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.room_service_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No orders ready for pickup'),
                  Text('Ready orders will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: waiterOrders.length,
            itemBuilder: (context, index) {
              final order = waiterOrders[index];
              return _buildReadyOrderCard(order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(waiterReadyOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyOrderCard(Order order) {
    final isProcessing = ref.watch(isServingProvider);
    final prepSummary = WaiterService.getOrderPreparationSummary(order);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Table: ${order.tableNumber ?? 'No Table'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (order.customerName != null)
                        Text(
                          'Customer: ${order.customerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Preparation summary
            Row(
              children: [
                if (prepSummary['hasKitchenItems'])
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kitchen: ${prepSummary['kitchenItemsCount']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (prepSummary['hasBarItems'])
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_bar,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bar: ${prepSummary['barItemsCount']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Order total
            Text(
              'Total: ${CurrencyFormatter.format(order.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            if (order.readyAt != null)
              Text(
                'Ready since: ${_formatTime(order.readyAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : () => _markOrderServed(order),
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  isProcessing ? 'Marking as Served...' : 'Mark as Served',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _markOrderServed(Order order) async {
    final currentUser = ref.read(firebaseCurrentUserProvider);
    if (currentUser == null) return;

    try {
      final success = await ref
          .read(serviceProvider.notifier)
          .markOrderServed(order.id, currentUser.id);

      if (success) {
        if (mounted) {
          // Refresh the ready orders list
          ref.invalidate(waiterReadyOrdersProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${order.orderNumber} marked as served!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark order as served: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
