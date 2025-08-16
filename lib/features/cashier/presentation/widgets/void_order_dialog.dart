import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cashier_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/services/order_service.dart';
import '../../../../features/auth/providers/appwrite_auth_provider.dart';

class VoidOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const VoidOrderDialog({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<VoidOrderDialog> createState() => _VoidOrderDialogState();
}

class _VoidOrderDialogState extends ConsumerState<VoidOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _isProcessing = false;

  final List<String> _voidReasons = [
    'Customer request',
    'Kitchen unavailable',
    'Incorrect order',
    'Payment issue',
    'Table cancelled',
    'Item out of stock',
    'System error',
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
      title: Text('Void Order ${widget.order.id.substring(0, 8)}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The order will be permanently voided.',
                      style: TextStyle(
                        color: Colors.red,
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
                    'Items: ${widget.order.items.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Total: ${CurrencyFormatter.format(widget.order.total)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Void reason selection
            const Text(
              'Reason for voiding:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Select a reason',
                enabled: !_isProcessing,
              ),
              items: _voidReasons.map((reason) {
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
            
            // Custom reason input (when "Other" is selected or for additional details)
            if (_selectedReason == 'Other' || _selectedReason != null) ...[
              Text(
                _selectedReason == 'Other' ? 'Please specify:' : 'Additional details (optional):',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                enabled: !_isProcessing,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _selectedReason == 'Other' 
                      ? 'Enter reason for voiding'
                      : 'Add additional details (optional)',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canVoidOrder() ? null : _voidOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
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
              : const Text('Void Order'),
        ),
      ],
    );
  }

  bool _canVoidOrder() {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other' && _reasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _voidOrder() async {
    final currentUser = ref.read(appwriteCurrentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Prepare the void reason
    final reason = _selectedReason == 'Other' 
        ? _reasonController.text.trim()
        : _selectedReason! + 
          (_reasonController.text.trim().isNotEmpty 
              ? ' - ${_reasonController.text.trim()}' 
              : '');

    try {
      final success = await OrderService.voidOrder(
        widget.order.id,
        reason,
        currentUser.id,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${widget.order.id.substring(0, 8)} has been voided'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to void order'),
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