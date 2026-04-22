import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/order_payment_step_controller.dart';
import 'new_order_shared_widgets.dart';

class OrderPaymentStepPage extends GetView<OrderPaymentStepController> {
  const OrderPaymentStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      final discountType = cartController.discountType.value;
      final showDiscountField = discountType != null;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Text(
            'Payment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          CartSectionCard(
            title: 'Discount',
            subtitle:
                'Apply any order discount before entering the collected payment.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DiscountChip(
                      label: 'None',
                      selected: discountType == null,
                      onTap: () => cartController.setDiscountType(null),
                    ),
                    DiscountChip(
                      label: 'Amount',
                      selected: discountType == 'amount',
                      onTap: () => cartController.setDiscountType('amount'),
                    ),
                    DiscountChip(
                      label: 'Percent',
                      selected: discountType == 'percentage',
                      onTap: () => cartController.setDiscountType('percentage'),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: showDiscountField
                      ? Padding(
                          key: ValueKey(discountType),
                          padding: const EdgeInsets.only(top: 14),
                          child: TextField(
                            controller: cartController.discountValueController,
                            keyboardType: const TextInputType.numberWithOptions(
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
                            decoration: InputDecoration(
                              labelText: discountType == 'percentage'
                                  ? 'Discount percent'
                                  : 'Discount amount',
                              hintText: discountType == 'percentage'
                                  ? 'Enter percentage discount'
                                  : 'Enter fixed discount amount',
                              helperText: discountType == 'percentage'
                                  ? 'Allowed range: 0.00% to 100.00%'
                                  : null,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CartSectionCard(
            title: 'Order total',
            child: Column(
              children: [
                TotalRow(
                  label: 'Subtotal',
                  value: cartController.formatCurrency(
                    cartController.displaySubtotal,
                  ),
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'Discount',
                  value: cartController.formatCurrency(
                    cartController.displayDiscountAmount,
                  ),
                  highlighted: true,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TotalRow(
                    label: 'Grand total',
                    value: cartController.formatCurrency(
                      cartController.displayGrandTotal,
                    ),
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CartSectionCard(
            title: 'Payment amount',
            subtitle:
                'Enter only the new amount collected now. The app sends the cumulative paid amount to the backend.',
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
                    labelText: 'New payment amount',
                    hintText: 'Enter collected amount',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 16),
                TotalRow(
                  label: 'Previously paid',
                  value: cartController.formatCurrency(
                    cartController.savedPaymentAmount,
                  ),
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'New payment',
                  value: cartController.formatCurrency(
                    cartController.enteredPaymentAmount,
                  ),
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'Total paid',
                  value: cartController.formatCurrency(
                    cartController.cumulativePaymentAmount,
                  ),
                  strong: true,
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'Due amount',
                  value: cartController.formatCurrency(
                    cartController.displayDueAmount,
                  ),
                  highlighted: cartController.displayDueAmount > 0,
                ),
                const SizedBox(height: 14),
                _PaymentStatusBadge(
                  status: cartController.displayPaymentStatus,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (status) {
      'paid' => (
        background: const Color(0xFFDDF4E6),
        foreground: const Color(0xFF166534),
        label: 'Paid',
      ),
      'partial' => (
        background: const Color(0xFFFFF1CC),
        foreground: const Color(0xFF92400E),
        label: 'Partial',
      ),
      _ => (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
        label: 'Not paid',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: tone.foreground),
          const SizedBox(width: 10),
          Text(
            'Payment status: ${tone.label}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
