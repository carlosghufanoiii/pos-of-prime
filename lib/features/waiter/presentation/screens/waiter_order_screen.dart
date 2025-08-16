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
import '../../../../features/auth/providers/appwrite_auth_provider.dart';
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
        bottom: TabBar(
          controller: _tabController,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemCount item${itemCount != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          CurrencyFormatter.format(orderTotal),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _showOrderConfirmation,
                    child: const Text('Review Order'),
                  ),
                ],
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
        Expanded(
          child: _buildProductGrid(),
        ),
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
            ...categories.map((category) => CategoryChip(
              label: category,
              isSelected: selectedCategory == category,
              onPressed: () {
                ref.read(selectedCategoryProvider.notifier).state = category;
                ref.read(searchQueryProvider.notifier).state = '';
                _searchController.clear();
              },
            )),
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
          return const Center(
            child: Text('No products found'),
          );
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
            return ProductCard(
              product: product,
              onAddToCart: () => _addProductToCart(product),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _tableController,
            decoration: const InputDecoration(
              labelText: 'Table Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.table_restaurant),
            ),
            onChanged: (value) {
              ref.read(orderProvider.notifier).setTableNumber(value.isEmpty ? null : value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Customer Name (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              ref.read(orderProvider.notifier).setCustomerName(value.isEmpty ? null : value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.format(item.unitPrice),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (item.product.isAlcoholic)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Alcoholic',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    if (item.quantity > 1) {
                      ref.read(orderProvider.notifier).updateItemQuantity(
                        item.id,
                        item.quantity - 1,
                      );
                    } else {
                      ref.read(orderProvider.notifier).removeItem(item.id);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(orderProvider.notifier).updateItemQuantity(
                      item.id,
                      item.quantity + 1,
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            
            // Total price
            Text(
              CurrencyFormatter.format(item.totalPrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
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

  void _showOrderConfirmation() {
    final orderState = ref.read(orderProvider);
    final currentUser = ref.read(appwriteCurrentUserProvider);
    
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
              final order = ref.read(orderProvider.notifier).createOrder(
                currentUser.id,
                currentUser.displayName,
              );
              
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
                      content: Text('Order ${order.orderNumber} sent for approval!'),
                      backgroundColor: Colors.green,
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
    final currentUser = ref.watch(appwriteCurrentUserProvider);
    final readyOrdersAsync = ref.watch(waiterReadyOrdersProvider);
    
    return RefreshIndicator(
      onRefresh: () => ref.refresh(waiterReadyOrdersProvider.future),
      child: readyOrdersAsync.when(
        data: (orders) {
          // Filter orders for current waiter or show all if needed
          final waiterOrders = orders.where((order) => 
              order.waiterId == currentUser?.id).toList();
          
          if (waiterOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.room_service_outlined, size: 64, color: Colors.grey),
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant, size: 16, color: Colors.orange),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_bar, size: 16, color: Colors.blue),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            if (order.readyAt != null)
              Text(
                'Ready since: ${_formatTime(order.readyAt!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
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
                label: Text(isProcessing ? 'Marking as Served...' : 'Mark as Served'),
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
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;
    
    try {
      final success = await ref.read(serviceProvider.notifier).markOrderServed(
        order.id,
        currentUser.id,
      );
      
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