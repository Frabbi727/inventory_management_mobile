import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:b2b_inventory_management/core/offline/sync_manager.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_payment_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';

class OrderPaymentStepPage extends GetView<OrderPaymentStepController> {
  const OrderPaymentStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      final discountType = cartController.discountType.value;
      final isAmountDiscount = discountType == 'amount';
      final discountAmount = cartController.displayDiscountAmount;
      final due = cartController.displayDueAmount;
      final underpaid = cartController.enteredPaymentAmount > 0 && due > 0;
      final isOnline = Get.isRegistered<SyncManager>()
          ? Get.find<SyncManager>().isOnline.value
          : true;

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
          if (cartController.stockWarningSummary != null) ...[
            InlineWarningBanner(message: cartController.stockWarningSummary!),
            const SizedBox(height: 14),
          ],
          _GrandTotalCard(cartController: cartController),
          const SizedBox(height: 18),
          const _PaymentSectionTitle(title: 'Discount'),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final percent in const <num>[0, 2, 5, 10]) ...[
                      _QuickActionChip(
                        label: '$percent%',
                        selected: cartController.isQuickPercentSelected(
                          percent,
                        ),
                        onTap: () =>
                            cartController.applyQuickPercentDiscount(percent),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _QuickActionChip(
                      label: '৳',
                      selected: isAmountDiscount,
                      onTap: () => cartController.setDiscountType('amount'),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: isAmountDiscount
                      ? Padding(
                          key: const ValueKey('amount-discount'),
                          padding: const EdgeInsets.only(top: 12),
                          child: TextField(
                            controller: cartController.discountValueController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}$'),
                              ),
                            ],
                            onChanged: cartController.onDiscountValueChanged,
                            onEditingComplete: () {
                              cartController.normalizeDiscountInputText();
                              FocusScope.of(context).unfocus();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Discount amount',
                              hintText: 'Enter fixed discount amount',
                              prefixText: '৳ ',
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (discountAmount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${cartController.formatCurrency(discountAmount)} off the subtotal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _PaymentSectionTitle(title: 'Payment'),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: cartController.paymentAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}$'),
                    ),
                  ],
                  onChanged: cartController.onPaymentAmountChanged,
                  onEditingComplete: () {
                    cartController.normalizePaymentInputText();
                    FocusScope.of(context).unfocus();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Add payment amount',
                    hintText: '0 — payment received now',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuickActionChip(
                      label: '25%',
                      selected: false,
                      onTap: () => cartController.applyPaymentFraction(0.25),
                    ),
                    const SizedBox(width: 6),
                    _QuickActionChip(
                      label: '50%',
                      selected: false,
                      onTap: () => cartController.applyPaymentFraction(0.5),
                    ),
                    const SizedBox(width: 6),
                    _QuickActionChip(
                      label: 'Full',
                      selected: false,
                      onTap: () => cartController.applyPaymentFraction(1),
                    ),
                  ],
                ),
                if (underpaid) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFADC8E)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '${cartController.formatCurrency(due)} will remain due. Full payment is required before confirm.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            child: Column(
              children: [
                if (cartController.savedPaymentAmount > 0) ...[
                  _PaymentRow(
                    label: 'Previously paid',
                    value: cartController.formatCurrency(
                      cartController.savedPaymentAmount,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _PaymentRow(
                  label: 'New payment',
                  value: cartController.formatCurrency(
                    cartController.enteredPaymentAmount,
                  ),
                ),
                const SizedBox(height: 8),
                _PaymentRow(
                  label: 'Total paid',
                  value: cartController.formatCurrency(
                    cartController.cumulativePaymentAmount,
                  ),
                  strong: true,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due amount',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      cartController.formatCurrency(due),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: due > 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment status',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _PaymentStatusPill(
                      status: cartController.displayPaymentStatus,
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

class _GrandTotalCard extends StatelessWidget {
  const _GrandTotalCard({required this.cartController});

  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discountAmount = cartController.displayDiscountAmount;

    Widget row(String label, String value, {bool grand = false}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: grand ? Colors.white : Colors.white.withValues(alpha: 0.72),
                fontWeight: grand ? FontWeight.w700 : FontWeight.w600,
                fontSize: grand ? 13 : 12.5,
              ),
            ),
          ),
          Text(
            value,
            style: grand
                ? theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          row(
            'Subtotal',
            cartController.formatCurrency(cartController.displaySubtotal),
          ),
          const SizedBox(height: 6),
          row(
            'Discount',
            discountAmount > 0
                ? '− ${cartController.formatCurrency(discountAmount)}'
                : '—',
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          row(
            'Grand Total',
            cartController.formatCurrency(cartController.displayGrandTotal),
            grand: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentSectionTitle extends StatelessWidget {
  const _PaymentSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: strong
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (status) {
      'paid' => (
        background: const Color(0xFFDCFCE7),
        foreground: const Color(0xFF16A34A),
        label: 'Paid',
      ),
      'partial' => (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFFD97706),
        label: 'Partial',
      ),
      _ => (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFFD97706),
        label: 'Not paid',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3.5, backgroundColor: tone.foreground),
          const SizedBox(width: 6),
          Text(
            tone.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
