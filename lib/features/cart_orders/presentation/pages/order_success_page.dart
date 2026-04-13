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
    final isConfirmed = (order?.status ?? '').toLowerCase() == 'confirmed';
    final pageTitle = isConfirmed ? 'Order Confirmed' : 'Draft Saved';
    final pageMessage = isConfirmed
        ? 'The order is confirmed and ready for follow-up.'
        : 'The draft is saved on the server and can be updated later.';

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _SuccessCard(
                title: response?.message ?? pageTitle,
                message: pageMessage,
              ),
              const SizedBox(height: 16),
              _DetailCard(
                title: 'Order summary',
                child: Column(
                  children: [
                    _DetailRow(label: 'Order No', value: order?.orderNo ?? '-'),
                    _DetailRow(
                      label: 'Order date',
                      value: _formatOrderDate(order?.orderDate),
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
                      value: order?.status ?? (isConfirmed ? 'confirmed' : 'draft'),
                      badge: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(
                title: 'Items',
                child: items.isEmpty
                    ? Text(
                        'No items returned by the server.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _SuccessItemRow(
                              index: index + 1,
                              item: items[index],
                            ),
                            if (index != items.length - 1) ...[
                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
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
                      highlighted: true,
                    ),
                    _DetailRow(
                      label: 'Grand total',
                      value: _formatCurrency(order?.grandTotal),
                      strong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if ((order?.note ?? '').trim().isNotEmpty)
                _DetailCard(
                  title: 'Note',
                  child: Text(
                    order!.note!.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('View Orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _startNewOrder(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
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

  static String _formatOrderDate(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(rawValue)?.toLocal();
    if (parsed == null) {
      return rawValue;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlighted = false,
    this.badge = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool highlighted;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = strong
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : highlighted
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: highlighted
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : EdgeInsets.zero,
        decoration: highlighted
            ? BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: highlighted
                    ? theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            if (badge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _titleCase(value),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              SizedBox(
                width: 120,
                child: Text(value, textAlign: TextAlign.right, style: style),
              ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String input) {
    if (input.isEmpty) {
      return input;
    }

    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_rounded,
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessItemRow extends StatelessWidget {
  const _SuccessItemRow({required this.index, required this.item});

  final int index;
  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity ?? 0} x ${OrderSuccessPage._formatCurrency(item.unitPrice)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            OrderSuccessPage._formatCurrency(item.lineTotal),
            textAlign: TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
