import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/order_flow_widgets.dart';
import '../../controllers/order_confirm_step_controller.dart';
import 'new_order_shared_widgets.dart';

class OrderConfirmStepPage extends GetView<OrderConfirmStepController> {
  const OrderConfirmStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      final customer = cartController.selectedCustomer.value;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Text(
            'Confirm order',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (cartController.hasSavedDraft) ...[
            DraftStatusCard(controller: cartController),
            const SizedBox(height: 16),
          ],
          if (cartController.stockWarningSummary != null) ...[
            InlineWarningBanner(message: cartController.stockWarningSummary!),
            const SizedBox(height: 16),
          ],
          if (customer != null) ...[
            CartCustomerSummaryCard(customer: customer),
            const SizedBox(height: 16),
          ],
          CartSectionCard(
            title: 'Items',
            child: cartController.items.isEmpty
                ? Text(
                    'No products selected yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < cartController.items.length;
                        index++
                      ) ...[
                        ConfirmRow(
                          count: index + 1,
                          title:
                              cartController.items[index].product.name ??
                              'Unnamed product',
                          subtitle: [
                            if ((cartController.items[index].variantLabel ?? '')
                                .isNotEmpty)
                              cartController.items[index].variantLabel!,
                            '${cartController.items[index].quantity} x ${cartController.formatCurrency(cartController.items[index].unitPrice)}',
                          ].join(' • '),
                          value: cartController.formatCurrency(
                            cartController.items[index].lineTotal,
                          ),
                        ),
                        if (index != cartController.items.length - 1) ...[
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
          CartSectionCard(
            title: 'Order summary',
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
                    label: 'Total',
                    value: cartController.formatCurrency(
                      cartController.displayGrandTotal,
                    ),
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          if (cartController.noteText.value.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            CartSectionCard(
              title: 'Note',
              child: Text(
                cartController.noteText.value.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],
        ],
      );
    });
  }
}
