import 'package:flutter/material.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/models/product.dart';

class KitchenOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onStartPrep;
  final VoidCallback? onMarkReady;
  final VoidCallback? onDelay;
  final bool showStartButton;
  final bool showReadyButton;
  final bool showPrepTime;
  final bool showWaitingTime;
  final bool isCompleted;

  const KitchenOrderCard({
    super.key,
    required this.order,
    this.onStartPrep,
    this.onMarkReady,
    this.onDelay,
    this.showStartButton = false,
    this.showReadyButton = false,
    this.showPrepTime = false,
    this.showWaitingTime = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 1 : 3,
      color: isCompleted ? Colors.grey[100] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header with priority indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isPriorityOrder())
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PRIORITY',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (order.tableNumber != null)
                        Text(
                          'Table: ${order.tableNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status and timing badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          order.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            order.status,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildTimeDisplay(),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer info
            if (order.customerName != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.restaurant_menu,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Waiter: ${order.waiterName}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Kitchen items only
            _buildKitchenItems(),

            const SizedBox(height: 12),

            // Order notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            if (showStartButton || showReadyButton) ...[
              const Divider(),
              Row(
                children: [
                  if (showStartButton) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onStartPrep,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Start Preparation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelay,
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Delay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],

                  if (showReadyButton) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onMarkReady,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Ready'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelay,
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Delay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenItems() {
    final kitchenItems = order.items
        .where(
          (item) => item.product.preparationArea == PreparationArea.kitchen,
        )
        .toList();

    if (kitchenItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'No kitchen items',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kitchenItems.length} Kitchen Item${kitchenItems.length != 1 ? 's' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...kitchenItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (item.product.description != null)
                          Text(
                            item.product.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Note: ${item.notes}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    if (showPrepTime && order.prepStartedAt != null) {
      final prepTime = DateTime.now().difference(order.prepStartedAt!);
      final minutes = prepTime.inMinutes;

      Color color = Colors.green;
      if (minutes > 30) {
        color = Colors.red;
      } else if (minutes > 20) {
        color = Colors.orange;
      }

      return Text(
        'Prep: ${minutes}m',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    }

    if (showWaitingTime && order.readyAt != null) {
      final waitTime = DateTime.now().difference(order.readyAt!);
      final minutes = waitTime.inMinutes;

      Color color = Colors.blue;
      if (minutes > 10) {
        color = Colors.red;
      } else if (minutes > 5) {
        color = Colors.orange;
      }

      return Text(
        'Ready: ${minutes}m ago',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    }

    // Default: show order age
    final orderAge = DateTime.now().difference(order.createdAt);
    final minutes = orderAge.inMinutes;

    return Text(
      '${minutes}m ago',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }

  bool _isPriorityOrder() {
    // Priority conditions
    final orderAge = DateTime.now().difference(order.createdAt);
    return orderAge.inMinutes > 20 ||
        (order.notes?.toLowerCase().contains('priority') ?? false) ||
        (order.notes?.toLowerCase().contains('rush') ?? false);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.approved:
        return Colors.orange;
      case OrderStatus.inPrep:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
