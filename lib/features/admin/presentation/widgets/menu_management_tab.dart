import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/models/menu_category.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../providers/menu_management_provider.dart';
import '../dialogs/add_category_dialog.dart';
import '../dialogs/edit_category_dialog.dart';
import '../dialogs/add_menu_item_dialog.dart';
import '../dialogs/edit_menu_item_dialog.dart';

class MenuManagementTab extends ConsumerStatefulWidget {
  const MenuManagementTab({super.key});

  @override
  ConsumerState<MenuManagementTab> createState() => _MenuManagementTabState();
}

class _MenuManagementTabState extends ConsumerState<MenuManagementTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to menu management state changes
    ref.listen<MenuManagementState>(menuManagementControllerProvider, (
      previous,
      next,
    ) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(menuManagementControllerProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        ref.read(menuManagementControllerProvider.notifier).clearMessages();
        // Optimized refresh - invalidate all necessary providers
        ref.invalidate(foodMenuStructureProvider);
        ref.invalidate(alcoholMenuStructureProvider);
        ref.invalidate(foodCategoriesProvider);
        ref.invalidate(alcoholCategoriesProvider);
      }
    });

    return Column(
      children: [
        // Header Section - Responsive
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.primaryDark.withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return isMobile ? _buildMobileHeader(context) : _buildDesktopHeader(context);
            },
          ),
        ),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant), text: 'Food Menu'),
              Tab(icon: Icon(Icons.local_bar), text: 'Alcohol Menu'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MenuTypeView(categoryType: CategoryType.food),
              MenuTypeView(categoryType: CategoryType.alcohol),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _initializeDefaultCategories() async {
    final success = await ref
        .read(menuManagementControllerProvider.notifier)
        .initializeDefaultCategories();

    if (success) {
      // Refresh categories after initialization
      ref.invalidate(menuCategoriesProvider);
      ref.invalidate(foodCategoriesProvider);
      ref.invalidate(alcoholCategoriesProvider);
    }
  }

  // Responsive header methods
  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Organize menu items into categories for Kitchen and Bar',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _initializeDefaultCategories(),
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: const Text('Setup Default Categories'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Organize menu items into categories for Kitchen and Bar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _initializeDefaultCategories(),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Setup Default Categories'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class MenuTypeView extends ConsumerWidget {
  final CategoryType categoryType;

  const MenuTypeView({super.key, required this.categoryType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuStructureProvider = categoryType == CategoryType.food
        ? foodMenuStructureProvider
        : alcoholMenuStructureProvider;

    final menuStructureAsync = ref.watch(menuStructureProvider);

    return menuStructureAsync.when(
      data: (menuStructure) => _buildMenuStructure(context, ref, menuStructure),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(menuStructureProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuStructure(
    BuildContext context,
    WidgetRef ref,
    Map<MenuCategory, List<Product>> menuStructure,
  ) {
    if (menuStructure.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return Column(
      children: [
        // Add Category Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.add),
              label: Text('Add ${categoryType.displayName} Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),

        // Categories with Products - Optimized ListView
        Expanded(
          child: ListView.builder(
            itemCount: menuStructure.length,
            itemBuilder: (context, index) {
              final entry = menuStructure.entries.elementAt(index);
              final category = entry.key;
              final products = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildCategoryCard(context, ref, category, products),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            categoryType == CategoryType.food
                ? Icons.restaurant
                : Icons.local_bar,
            size: 64,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${categoryType.displayName} Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category to organize menu items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text('Create ${categoryType.displayName} Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    List<Product> products,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceGrey,
      child: Column(
        children: [
          // Category Header - Responsive
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return isMobile 
                    ? _buildMobileCategoryHeader(context, ref, category, products)
                    : _buildDesktopCategoryHeader(context, ref, category, products);
              },
            ),
          ),

          // Products List
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products in this category',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAddProductDialog(context, ref, category),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => Divider(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductItem(context, ref, category, product);
              },
            ),
        ],
      ),
    );
  }

  // Responsive category header methods
  Widget _buildMobileCategoryHeader(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    List<Product> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              categoryType == CategoryType.food ? Icons.restaurant : Icons.local_bar,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              color: AppTheme.deepBlack,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_product',
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Add Product', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_category',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Category', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_category',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Category', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'add_product':
                    _showAddProductDialog(context, ref, category);
                    break;
                  case 'edit_category':
                    _showEditCategoryDialog(context, ref, category);
                    break;
                  case 'delete_category':
                    _confirmDeleteCategory(context, ref, category);
                    break;
                }
              },
            ),
          ],
        ),
        if (category.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            category.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Chip(
          label: Text(
            '${products.length} items',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildDesktopCategoryHeader(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    List<Product> products,
  ) {
    return Row(
      children: [
        Icon(
          categoryType == CategoryType.food ? Icons.restaurant : Icons.local_bar,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (category.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        Chip(
          label: Text(
            '${products.length} items',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          side: BorderSide.none,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppTheme.deepBlack,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add_product',
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Add Product', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit_category',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Category', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_category',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete Category', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'add_product':
                _showAddProductDialog(context, ref, category);
                break;
              case 'edit_category':
                _showEditCategoryDialog(context, ref, category);
                break;
              case 'delete_category':
                _confirmDeleteCategory(context, ref, category);
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    Product product,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: 8,
          ),
          child: isMobile
              ? _buildMobileProductItem(context, ref, category, product)
              : _buildDesktopProductItem(context, ref, category, product),
        );
      },
    );
  }

  Widget _buildMobileProductItem(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    Product product,
  ) {
    return Card(
      color: AppTheme.surfaceGrey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: product.isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  child: Text(
                    product.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: product.isActive ? AppTheme.primaryColor : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          decoration: product.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      if (!product.isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  color: AppTheme.deepBlack,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: product.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            product.isActive ? Icons.visibility_off : Icons.visibility,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.isActive ? 'Deactivate' : 'Activate',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleProductAction(ref, context, category, product, value),
                ),
              ],
            ),
            if (product.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                product.description!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.stockQuantity <= 10
                        ? AppTheme.errorColor.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${product.stockQuantity}',
                    style: TextStyle(
                      color: product.stockQuantity <= 10 ? AppTheme.errorColor : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopProductItem(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    Product product,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: product.isActive
            ? AppTheme.primaryColor.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        child: Text(
          product.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: product.isActive ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: product.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (!product.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Inactive',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.description?.isNotEmpty ?? false) ...[
            Text(
              product.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Stock: ${product.stockQuantity}',
                style: TextStyle(
                  color: product.stockQuantity <= 10
                      ? AppTheme.errorColor
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        color: AppTheme.deepBlack,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Edit Product', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          PopupMenuItem(
            value: product.isActive ? 'deactivate' : 'activate',
            child: Row(
              children: [
                Icon(
                  product.isActive ? Icons.visibility_off : Icons.visibility,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  product.isActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Delete Product', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) => _handleProductAction(ref, context, category, product, value),
      ),
    );
  }

  void _handleProductAction(
    WidgetRef ref,
    BuildContext context,
    MenuCategory category,
    Product product,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(context, ref, category, product);
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(ref, product);
        break;
      case 'delete':
        _confirmDeleteProduct(context, ref, product);
        break;
    }
  }

  // ============ Dialog Methods ============

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(categoryType: categoryType),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(category: category),
    );
  }

  void _showAddProductDialog(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddMenuItemDialog(category: category),
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          EditMenuItemDialog(product: product, category: category),
    );
  }

  // ============ Action Methods ============

  Future<void> _toggleProductStatus(WidgetRef ref, Product product) async {
    final updatedProduct = product.copyWith(
      isActive: !product.isActive,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(menuManagementControllerProvider.notifier)
        .updateProduct(updatedProduct);
  }

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(menuManagementControllerProvider.notifier)
                  .deleteCategory(category.id, category.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        title: const Text(
          'Delete Product',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(menuManagementControllerProvider.notifier)
                  .deleteProduct(product.id, product.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
