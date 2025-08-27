import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_theme.dart';
import '../../../../shared/models/menu_category.dart';
import '../../../../shared/models/product.dart';
import '../../providers/menu_management_provider.dart';

class AddMenuItemDialog extends ConsumerStatefulWidget {
  final MenuCategory category;

  const AddMenuItemDialog({super.key, required this.category});

  @override
  ConsumerState<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends ConsumerState<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _costController = TextEditingController();

  String _unit = 'pcs';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuManagementControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Menu Item',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${widget.category.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Information
                      Text(
                        'Product Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name and SKU Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              enabled: !state.isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Product Name *',
                                hintText: 'e.g., ${_getProductHint()}',
                                prefixIcon: Icon(
                                  Icons.fastfood,
                                  color: AppTheme.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter product name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _skuController,
                              enabled: !state.isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'SKU',
                                hintText: 'AUTO',
                                prefixIcon: Icon(
                                  Icons.qr_code,
                                  color: AppTheme.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !state.isLoading,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the product',
                          prefixIcon: Icon(
                            Icons.description,
                            color: AppTheme.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          labelStyle: TextStyle(color: AppTheme.primaryColor),
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pricing & Inventory
                      Text(
                        'Pricing & Inventory',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price and Cost Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              enabled: !state.isLoading,
                              style: const TextStyle(color: Colors.white),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Selling Price *',
                                hintText: '0.00',
                                prefixIcon: Icon(
                                  Icons.attach_money,
                                  color: AppTheme.primaryColor,
                                ),
                                prefixText: '₱ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _costController,
                              enabled: !state.isLoading,
                              style: const TextStyle(color: Colors.white),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Cost Price',
                                hintText: '0.00',
                                prefixIcon: Icon(
                                  Icons.price_change,
                                  color: AppTheme.primaryColor,
                                ),
                                prefixText: '₱ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stock and Unit Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              enabled: !state.isLoading,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Initial Stock',
                                hintText: '0',
                                prefixIcon: Icon(
                                  Icons.inventory,
                                  color: AppTheme.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _unit,
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: AppTheme.deepBlack,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                prefixIcon: Icon(
                                  Icons.straighten,
                                  color: AppTheme.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              items:
                                  [
                                        'pcs',
                                        'ml',
                                        'oz',
                                        'kg',
                                        'g',
                                        'lbs',
                                        'bottle',
                                        'can',
                                        'glass',
                                      ]
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ),
                                      )
                                      .toList(),
                              onChanged: state.isLoading
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _unit = value;
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Switch
                      SwitchListTile(
                        title: const Text(
                          'Active Product',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Product will be available for ordering',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        value: _isActive,
                        onChanged: state.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                        activeThumbColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),

                      // Product Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Product Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Category: ${widget.category.name} (${widget.category.type.displayName})',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              '• Preparation Area: ${widget.category.type == CategoryType.food ? 'Kitchen' : 'Bar'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              '• Orders will be routed to the ${widget.category.type == CategoryType.food ? 'Kitchen Display' : 'Bar Display'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _createProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Create Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductHint() {
    if (widget.category.type == CategoryType.food) {
      return 'Grilled Chicken, Caesar Salad';
    } else {
      return 'Mojito, Craft Beer';
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Optimized batch data preparation
    final now = DateTime.now();
    final productId = '${widget.category.type.name.toUpperCase()}_${now.millisecondsSinceEpoch}';
    final sku = _skuController.text.trim().isEmpty
        ? 'PRD${now.millisecondsSinceEpoch}'
        : _skuController.text.trim();
    
    // Pre-calculate values
    final isAlcoholic = widget.category.type == CategoryType.alcohol;
    final preparationArea = isAlcoholic ? PreparationArea.bar : PreparationArea.kitchen;
    final description = _descriptionController.text.trim();
    final costText = _costController.text.trim();
    final stockText = _stockController.text.trim();

    final product = Product(
      id: productId,
      name: _nameController.text.trim(),
      sku: sku,
      price: double.parse(_priceController.text),
      category: widget.category.id,
      isAlcoholic: isAlcoholic,
      isActive: _isActive,
      description: description.isEmpty ? null : description,
      stockQuantity: stockText.isEmpty ? 0 : int.parse(stockText),
      unit: _unit,
      cost: costText.isEmpty ? null : double.parse(costText),
      preparationArea: preparationArea,
      createdAt: now,
      updatedAt: now,
    );

    // Close dialog immediately for better UX
    if (mounted) Navigator.pop(context);
    
    // Create product in background
    await ref
        .read(menuManagementControllerProvider.notifier)
        .createProduct(product);
  }
}
