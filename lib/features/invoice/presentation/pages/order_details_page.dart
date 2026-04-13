import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../cart_orders/data/models/order_item_model.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../../../cart_orders/presentation/controllers/cart_controller.dart';
import '../controllers/order_details_controller.dart';

class OrderDetailsPage extends GetView<OrderDetailsController> {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          Obx(() {
            final order = controller.order.value;
            if (order?.status != 'draft' || order?.id == null) {
              return const SizedBox.shrink();
            }

            return TextButton.icon(
              onPressed: () => _editDraft(order!),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.order.value == null) {
            return const _OrderDetailsLoadingState();
          }

          if (controller.errorMessage.value != null &&
              controller.order.value == null) {
            return AppMessageState(
              icon: Icons.cloud_off_outlined,
              message: controller.errorMessage.value!,
              actionLabel: 'Retry',
              onAction: controller.fetchOrderDetails,
            );
          }

          final order = controller.order.value;
          if (order == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _OrderOverviewCard(
                orderNo: order.orderNo ?? 'Order',
                date: controller.formatDate(order.orderDate),
                status: _titleCase(order.status),
                salesman: order.salesman?.name ?? '-',
              ),
              const SizedBox(height: 16),
              _SectionShell(
                title: 'Customer',
                child: _CustomerCard(
                  name: order.customer?.name ?? '-',
                  phone: order.customer?.phone ?? '-',
                ),
              ),
              const SizedBox(height: 16),
              _SectionShell(
                title: 'Items',
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < (order.items ?? const <OrderItemModel>[]).length;
                      index++
                    ) ...[
                      _ItemRowCard(
                        item: order.items![index],
                        formatCurrency: controller.formatCurrency,
                      ),
                      if (index != order.items!.length - 1)
                        const SizedBox(height: 12),
                    ],
                    if ((order.items ?? const <OrderItemModel>[]).isEmpty)
                      _EmptyItemsCard(
                        textColor: colorScheme.onSurfaceVariant,
                        borderColor: colorScheme.outlineVariant,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionShell(
                title: 'Summary',
                child: _SummaryCard(
                  subtotal: controller.formatCurrency(order.subtotal),
                  discount: controller.formatCurrency(order.discountAmount),
                  grandTotal: controller.formatCurrency(order.grandTotal),
                  note: order.note,
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

  Future<void> _editDraft(OrderModel order) async {
    final cartController = Get.find<CartController>();
    await cartController.hydrateDraftFromOrder(order);
    if (cartController.errorMessage.value != null) {
      return;
    }

    await Get.toNamed(AppRoutes.newOrder);
  }
}

class _OrderOverviewCard extends StatelessWidget {
  const _OrderOverviewCard({
    required this.orderNo,
    required this.date,
    required this.status,
    required this.salesman,
  });

  final String orderNo;
  final String date;
  final String status;
  final String salesman;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusTone = _statusTone(colorScheme, status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order no',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderNo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: status,
                  backgroundColor: statusTone.backgroundColor,
                  foregroundColor: statusTone.foregroundColor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InfoMetric(
                    label: 'Date',
                    value: date,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoMetric(
                    label: 'Salesman',
                    value: salesman,
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusTone _statusTone(ColorScheme colorScheme, String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const _StatusTone(
          backgroundColor: Color(0xFFDDF4E6),
          foregroundColor: Color(0xFF166534),
        );
      case 'draft':
        return const _StatusTone(
          backgroundColor: Color(0xFFFFF1CC),
          foregroundColor: Color(0xFF92400E),
        );
      case 'cancelled':
        return const _StatusTone(
          backgroundColor: Color(0xFFFEE2E2),
          foregroundColor: Color(0xFFB42318),
        );
      default:
        return _StatusTone(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.name, required this.phone});

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.groups_2_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.72,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.call_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            phone,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRowCard extends StatelessWidget {
  const _ItemRowCard({required this.item, required this.formatCurrency});

  final OrderItemModel item;
  final String Function(num? value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? '-',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.quantity ?? 0} x ${formatCurrency(item.unitPrice)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Line total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(item.lineTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.note,
  });

  final String subtotal;
  final String discount;
  final String grandTotal;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: subtotal),
            const SizedBox(height: 14),
            _SummaryRow(label: 'Discount', value: discount),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _SummaryRow(
                label: 'Grand total',
                value: grandTotal,
                strong: true,
                valueColor: colorScheme.onPrimaryContainer,
                labelColor: colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.82,
                ),
              ),
            ),
            if ((note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.labelColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? labelColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: labelColor ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          textAlign: TextAlign.right,
          style:
              (strong
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard({required this.textColor, required this.borderColor});

  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        'No items found for this order.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderDetailsLoadingState extends StatelessWidget {
  const _OrderDetailsLoadingState();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SkeletonCard(height: 150, color: baseColor),
        const SizedBox(height: 16),
        _SkeletonCard(height: 110, color: baseColor),
        const SizedBox(height: 16),
        _SkeletonCard(height: 190, color: baseColor),
        const SizedBox(height: 16),
        _SkeletonCard(height: 180, color: baseColor),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _StatusTone {
  const _StatusTone({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}
