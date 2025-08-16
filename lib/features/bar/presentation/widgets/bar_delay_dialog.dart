import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bar_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/models/product.dart';
import '../../../../features/auth/providers/appwrite_auth_provider.dart';

class BarDelayDialog extends ConsumerStatefulWidget {
  final Order order;

  const BarDelayDialog({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<BarDelayDialog> createState() => _BarDelayDialogState();
}

class _BarDelayDialogState extends ConsumerState<BarDelayDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  int _estimatedMinutes = 10;
  bool _isProcessing = false;

  final List<String> _delayReasons = [
    'Out of ingredients',
    'Blender/equipment issue',
    'Ice shortage',
    'Complex cocktail preparation',
    'Waiting for glassware',
    'Staff shortage',
    'Multiple orders queue',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delay Bar Order ${widget.order.orderNumber}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.cyan, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will notify the waiter and cashier about the drink delay.',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Order summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.order.tableNumber != null)
                    Text('Table: ${widget.order.tableNumber}'),
                  if (widget.order.customerName != null)
                    Text('Customer: ${widget.order.customerName}'),
                  Text('Waiter: ${widget.order.waiterName}'),
                  const SizedBox(height: 8),
                  Text(
                    'Bar Items: ${widget.order.items.where((item) => item.product.preparationArea == PreparationArea.bar).length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // Show if alcoholic drinks are included
                  if (_hasAlcoholicDrinks()) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.wine_bar, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Contains alcoholic beverages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delay reason selection
            const Text(
              'Reason for delay:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Select a reason',
                enabled: !_isProcessing,
              ),
              items: _delayReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                  if (value != 'Other') {
                    _reasonController.text = value ?? '';
                  } else {
                    _reasonController.clear();
                  }
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Custom reason input
            if (_selectedReason == 'Other' || _selectedReason != null) ...[ 
              Text(
                _selectedReason == 'Other' ? 'Please specify:' : 'Additional details (optional):',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                enabled: !_isProcessing,
                maxLines: 2,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _selectedReason == 'Other' 
                      ? 'Enter reason for delay'
                      : 'Add additional details (optional)',
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Estimated delay time
            const Text(
              'Estimated additional time:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Slider(
                        value: _estimatedMinutes.toDouble(),
                        min: 2,
                        max: 30,
                        divisions: 14,
                        label: '$_estimatedMinutes minutes',
                        onChanged: _isProcessing ? null : (value) {
                          setState(() {
                            _estimatedMinutes = value.round();
                          });
                        },
                      ),
                      Text(
                        '$_estimatedMinutes minutes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Quick time buttons (bar-specific shorter times)
            Wrap(
              spacing: 8,
              children: [2, 5, 10, 15, 20, 30].map((minutes) {
                final isSelected = _estimatedMinutes == minutes;
                return FilterChip(
                  label: Text('${minutes}m'),
                  selected: isSelected,
                  onSelected: _isProcessing ? null : (selected) {
                    if (selected) {
                      setState(() {
                        _estimatedMinutes = minutes;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canSubmitDelay() ? null : _submitDelay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Report Delay'),
        ),
      ],
    );
  }

  bool _hasAlcoholicDrinks() {
    return widget.order.items.any((item) => 
        item.product.preparationArea == PreparationArea.bar && 
        item.product.isAlcoholic);
  }

  bool _canSubmitDelay() {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other' && _reasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _submitDelay() async {
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Prepare the delay reason
    final reason = _selectedReason == 'Other' 
        ? _reasonController.text.trim()
        : _selectedReason! + 
          (_reasonController.text.trim().isNotEmpty 
              ? ' - ${_reasonController.text.trim()}' 
              : '');

    try {
      final success = await ref.read(barOrderStatusProvider.notifier).delayOrder(
        widget.order.id,
        reason,
        _estimatedMinutes,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delay reported for Bar Order ${widget.order.orderNumber}'),
              backgroundColor: Colors.cyan,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to report delay'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}