import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/home_controller.dart';
import '../../data/models/create_order_response_model.dart';
import '../../data/models/order_item_model.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final response = Get.arguments as CreateOrderResponseModel?;
    final order = response?.data;
    final items = order?.items ?? const <OrderItemModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Order Created')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      response?.message ?? 'Order created successfully.',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The order is now confirmed and ready for follow-up.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(
                title: 'Order summary',
                child: Column(
                  children: [
                    _DetailRow(label: 'Order No', value: order?.orderNo ?? '-'),
                    _DetailRow(
                      label: 'Order date',
                      value: order?.orderDate ?? '-',
                    ),
                    _DetailRow(
                      label: 'Customer',
                      value: order?.customer?.name ?? '-',
                    ),
                    _DetailRow(
                      label: 'Phone',
                      value: order?.customer?.phone ?? '-',
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: order?.status ?? 'confirmed',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                title: 'Items',
                child: items.isEmpty
                    ? const Text('No items returned by the server.')
                    : Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName ?? 'Product',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.quantity ?? 0} x ${_formatCurrency(item.unitPrice)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(item.lineTotal),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                title: 'Totals',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Subtotal',
                      value: _formatCurrency(order?.subtotal),
                    ),
                    _DetailRow(
                      label: 'Discount',
                      value: _formatCurrency(order?.discountAmount),
                    ),
                    _DetailRow(
                      label: 'Grand total',
                      value: _formatCurrency(order?.grandTotal),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToTab(2),
                  child: const Text('View Orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _startNewOrder(),
                  child: const Text('New Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToTab(int index) {
    Get.until((route) => route.settings.name == AppRoutes.home);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(index);
    }
  }

  void _startNewOrder() {
    Get.until((route) => route.settings.name == AppRoutes.home);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(0);
    }
    Get.toNamed(AppRoutes.newOrder);
  }

  static String _formatCurrency(num? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
    final style = strong
        ? Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
