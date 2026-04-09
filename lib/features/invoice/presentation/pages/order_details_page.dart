import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../cart_orders/data/models/order_item_model.dart';
import '../controllers/order_details_controller.dart';

class OrderDetailsPage extends GetView<OrderDetailsController> {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.order.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null &&
              controller.order.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.fetchOrderDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final order = controller.order.value;
          if (order == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: order.orderNo ?? 'Order',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Date',
                      value: controller.formatDate(order.orderDate),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Status',
                      value: _titleCase(order.status),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Salesman',
                      value: order.salesman?.name ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Customer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer?.name ?? '-',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(order.customer?.phone ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Items',
                child: Column(
                  children: [
                    for (final item in order.items ?? const <OrderItemModel>[])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ItemTile(
                          item: item,
                          formatCurrency: controller.formatCurrency,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Summary',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Subtotal',
                      value: controller.formatCurrency(order.subtotal),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Discount',
                      value: controller.formatCurrency(order.discountAmount),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Grand total',
                      value: controller.formatCurrency(order.grandTotal),
                      strong: true,
                    ),
                    if ((order.note ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DetailRow(label: 'Note', value: order.note!),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _titleCase(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: strong
                ? Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                : null,
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.formatCurrency});

  final OrderItemModel item;
  final String Function(num? value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? '-',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity ?? 0} x ${formatCurrency(item.unitPrice)}',
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(item.lineTotal),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
