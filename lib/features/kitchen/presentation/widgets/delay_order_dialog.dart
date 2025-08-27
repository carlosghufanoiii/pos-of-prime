import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kitchen_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/models/product.dart';
import '../../../../features/auth/providers/firebase_auth_provider.dart';

class DelayOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const DelayOrderDialog({super.key, required this.order});

  @override
  ConsumerState<DelayOrderDialog> createState() => _DelayOrderDialogState();
}

class _DelayOrderDialogState extends ConsumerState<DelayOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  int _estimatedMinutes = 15;
  bool _isProcessing = false;

  final List<String> _delayReasons = [
    'Missing ingredients',
    'Equipment issue',
    'High volume',
    'Complex preparation',
    'Waiting for other orders',
    'Staff shortage',
    'Special dietary requirements',
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
      title: Text('Delay Order ${widget.order.orderNumber}'),
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will notify the cashier and waiter about the delay.',
                      style: TextStyle(
                        color: Colors.orange,
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
                    'Kitchen Items: ${widget.order.items.where((item) => item.product.preparationArea == PreparationArea.kitchen).length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
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
              initialValue: _selectedReason,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Select a reason',
                enabled: !_isProcessing,
              ),
              items: _delayReasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
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
                _selectedReason == 'Other'
                    ? 'Please specify:'
                    : 'Additional details (optional):',
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
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '$_estimatedMinutes minutes',
                        onChanged: _isProcessing
                            ? null
                            : (value) {
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

            // Quick time buttons
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20, 30, 45].map((minutes) {
                final isSelected = _estimatedMinutes == minutes;
                return FilterChip(
                  label: Text('${minutes}m'),
                  selected: isSelected,
                  onSelected: _isProcessing
                      ? null
                      : (selected) {
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
            backgroundColor: Colors.orange,
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

  bool _canSubmitDelay() {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other' && _reasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _submitDelay() async {
    final currentUser = ref.read(firebaseCurrentUserProvider);
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
      final success = await ref
          .read(orderStatusProvider.notifier)
          .delayOrder(widget.order.id, reason, _estimatedMinutes);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Delay reported for Order ${widget.order.orderNumber}',
              ),
              backgroundColor: Colors.orange,
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
