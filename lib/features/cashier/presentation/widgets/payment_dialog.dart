import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cashier_provider.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../features/auth/providers/firebase_auth_provider.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final Order order;

  const PaymentDialog({super.key, required this.order});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  PaymentMethod? _selectedPaymentMethod;
  double? _amountReceived;
  double _changeAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.order.total.toStringAsFixed(2);
    _amountReceived = widget.order.total;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final isProcessing = paymentState.isProcessing;

    return AlertDialog(
      title: Text('Process Payment - Order ${widget.order.id.substring(0, 8)}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(CurrencyFormatter.format(widget.order.subtotal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (12%):'),
                      Text(CurrencyFormatter.format(widget.order.taxAmount)),
                    ],
                  ),
                  if (widget.order.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          '-${CurrencyFormatter.format(widget.order.discount)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.order.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment method selection
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return FilterChip(
                  label: Text(_getPaymentMethodLabel(method)),
                  selected: isSelected,
                  onSelected: isProcessing
                      ? null
                      : (selected) {
                          setState(() {
                            _selectedPaymentMethod = selected ? method : null;
                          });

                          if (selected) {
                            ref
                                .read(paymentProvider.notifier)
                                .setPaymentMethod(method);

                            // Auto-fill amount for non-cash payments
                            if (method != PaymentMethod.cash) {
                              _amountController.text = widget.order.total
                                  .toStringAsFixed(2);
                              _amountReceived = widget.order.total;
                              _changeAmount = 0.0;
                            }
                          }
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Amount received (for cash payments)
            if (_selectedPaymentMethod == PaymentMethod.cash) ...[
              const Text(
                'Amount Received',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                enabled: !isProcessing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: '₱ ',
                  hintText: 'Enter amount received',
                  errorText:
                      _amountReceived != null &&
                          _amountReceived! < widget.order.total
                      ? 'Insufficient amount'
                      : null,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _amountReceived = amount;
                    _changeAmount = amount != null
                        ? amount - widget.order.total
                        : 0.0;
                  });

                  if (amount != null) {
                    ref
                        .read(paymentProvider.notifier)
                        .setAmountReceived(amount);
                  }
                },
              ),

              const SizedBox(height: 12),

              // Change amount
              if (_changeAmount != 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _changeAmount >= 0
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _changeAmount >= 0
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _changeAmount >= 0 ? 'Change:' : 'Shortage:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _changeAmount >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_changeAmount.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _changeAmount >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Quick amount buttons for cash
              const Text(
                'Quick Amounts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _getQuickAmounts(widget.order.total).map((amount) {
                  return OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () {
                            _amountController.text = amount.toStringAsFixed(2);
                            setState(() {
                              _amountReceived = amount;
                              _changeAmount = amount - widget.order.total;
                            });
                            ref
                                .read(paymentProvider.notifier)
                                .setAmountReceived(amount);
                          },
                    child: Text(CurrencyFormatter.format(amount)),
                  );
                }).toList(),
              ),
            ],

            // Error message
            if (paymentState.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        paymentState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isProcessing
              ? null
              : () {
                  ref.read(paymentProvider.notifier).resetPayment();
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isProcessing || !_canProcessPayment()
              ? null
              : _processPayment,
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Process Payment'),
        ),
      ],
    );
  }

  bool _canProcessPayment() {
    if (_selectedPaymentMethod == null) return false;

    if (_selectedPaymentMethod == PaymentMethod.cash) {
      return _amountReceived != null && _amountReceived! >= widget.order.total;
    }

    return true; // For card and e-wallet, exact amount is assumed
  }

  Future<void> _processPayment() async {
    final currentUser = ref.read(firebaseCurrentUserProvider);
    if (currentUser == null) return;

    final success = await ref
        .read(paymentProvider.notifier)
        .processPayment(currentUser.id, currentUser.name);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment processed successfully for Order ${widget.order.id.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Error is handled by the provider and displayed in the dialog
      }
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
    }
  }

  List<double> _getQuickAmounts(double total) {
    final roundedTotal = (total / 50).ceil() * 50;
    return [
      total, // Exact amount
      roundedTotal.toDouble(),
      (roundedTotal + 50).toDouble(),
      (roundedTotal + 100).toDouble(),
      1000.0,
    ].toSet().toList()..sort();
  }
}
