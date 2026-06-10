import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b2b_inventory_management/core/offline/sync_manager.dart';

import '../../../data/models/cart_item_model.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_cart_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';
import 'new_order_shared_widgets.dart';

class OrderReviewStepPage extends GetView<OrderCartStepController> {
  const OrderReviewStepPage({super.key});

  static const _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]} ${value.year}';

  static String _formatDateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]}, '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      if (cartController.items.isEmpty) {
        return EmptyCartState(onBackToProducts: controller.goToProductsStep);
      }

      final customer = cartController.selectedCustomer.value;
      final isOnline = Get.isRegistered<SyncManager>()
          ? Get.find<SyncManager>().isOnline.value
          : true;
      final deliveryAt = cartController.selectedIntendedDeliveryAt.value;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          if (!isOnline) ...[
            const InlineWarningBanner(
              message:
                  'You are currently offline. You can save this order as a draft, but confirming requires an internet connection.',
            ),
            const SizedBox(height: 14),
          ],
          if (cartController.hasSavedDraft) ...[
            DraftStatusCard(controller: cartController),
            const SizedBox(height: 14),
          ],
          if (cartController.stockWarningSummary != null) ...[
            InlineWarningBanner(message: cartController.stockWarningSummary!),
            const SizedBox(height: 14),
          ],
          if (customer != null) ...[
            CartCustomerSummaryCard(customer: customer),
            const SizedBox(height: 14),
          ],
          _ReviewSectionTitle(
            title: 'Items · ${cartController.items.length}',
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < cartController.items.length;
                  index++
                ) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  _ReviewItemRow(
                    item: cartController.items[index],
                    cartController: cartController,
                    onIncrement: () => controller.incrementQuantity(
                      cartController.items[index].lineKey,
                    ),
                    onDecrement: () => controller.decrementQuantity(
                      cartController.items[index].lineKey,
                    ),
                    onRemove: () => controller.removeItem(
                      cartController.items[index].lineKey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ReviewSectionTitle(title: 'Order note', optional: true),
          const SizedBox(height: 10),
          TextField(
            controller: cartController.noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. Deliver before 3 PM · printed invoice',
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Order date',
                  value: _formatDate(cartController.selectedOrderDate.value),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Delivery',
                  value: deliveryAt == null
                      ? 'Not set'
                      : _formatDateTime(deliveryAt),
                  onEdit: () =>
                      cartController.goToStep(CartController.customerStep),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Subtotal',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      cartController.formatCurrency(cartController.subtotal),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _ReviewSectionTitle extends StatelessWidget {
  const _ReviewSectionTitle({required this.title, this.optional = false});

  final String title;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        if (optional)
          Text(
            ' (optional)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ReviewItemRow extends StatelessWidget {
  const _ReviewItemRow({
    required this.item,
    required this.cartController,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItemModel item;
  final CartController cartController;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canIncrement = cartController.canIncrementQuantity(item.lineKey);
    final warning = item.isOutOfStock
        ? 'Out of stock — confirm is blocked until this line is fixed.'
        : item.exceedsAvailableStock
        ? 'Exceeds available stock (${item.availableStock ?? 0}).'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: item.product.name ?? 'Unnamed product',
                        children: [
                          if ((item.variantLabel ?? '').isNotEmpty)
                            TextSpan(
                              text: ' · ${item.variantLabel}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cartController.formatCurrency(item.unitPrice)} each',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CompactQty(
                quantity: item.quantity,
                canIncrement: canIncrement,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  cartController.formatCurrency(item.lineTotal),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Remove',
                color: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactQty extends StatelessWidget {
  const _CompactQty({
    required this.quantity,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildButton(IconData icon, VoidCallback? onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 30,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? theme.colorScheme.outline
                : theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildButton(Icons.remove_rounded, onDecrement),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          buildButton(Icons.add_rounded, canIncrement ? onIncrement : null),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.onEdit});

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.edit_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
