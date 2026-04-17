import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/order_cart_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';
import 'new_order_shared_widgets.dart';

class OrderCartStepPage extends GetView<OrderCartStepController> {
  const OrderCartStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      if (cartController.items.isEmpty) {
        return EmptyCartState(onBackToProducts: controller.goToProductsStep);
      }

      final customer = cartController.selectedCustomer.value;
      final discountType = cartController.discountType.value;
      final showDiscountField = discountType != null;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          if (customer != null) ...[
            CartCustomerSummaryCard(customer: customer),
            const SizedBox(height: 20),
          ],
          Text(
            'Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in cartController.items) ...[
            CartItemWidget(
              title: item.product.name ?? 'Unnamed product',
              subtitle: item.product.sku ?? '-',
              variantLabel: item.variantLabel,
              quantity: item.quantity,
              unitPrice: cartController.formatCurrency(item.unitPrice),
              lineTotal: cartController.formatCurrency(item.lineTotal),
              availableStock: item.availableStock,
              canIncrement: cartController.canIncrementQuantity(item.lineKey),
              onIncrement: () => controller.incrementQuantity(item.lineKey),
              onDecrement: () => controller.decrementQuantity(item.lineKey),
              onQuantitySubmitted: (value) =>
                  controller.updateQuantity(item.lineKey, value),
              onRemove: () => controller.removeItem(item.lineKey),
              warningMessage: item.isOutOfStock
                  ? 'This item is currently out of stock. Keep it only if you plan to revise the draft.'
                  : item.exceedsAvailableStock
                  ? 'Requested quantity is above available stock (${item.availableStock ?? 0}). Draft save is allowed, but confirm is blocked.'
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          CartSectionCard(
            title: 'Discount',
            subtitle:
                'Select the discount type first, then enter a value if needed.',
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
            title: 'Order note',
            subtitle: 'Optional delivery instructions or internal order note.',
            child: TextField(
              controller: cartController.noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add an optional note',
              ),
            ),
          ),
          const SizedBox(height: 16),
          CartSectionCard(
            title: 'Order totals',
            child: Column(
              children: [
                TotalRow(
                  label: 'Subtotal',
                  value: cartController.formatCurrency(cartController.subtotal),
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'Discount',
                  value: cartController.formatCurrency(
                    cartController.estimatedDiscountAmount,
                  ),
                ),
                const SizedBox(height: 12),
                TotalRow(
                  label: 'Total',
                  value: cartController.formatCurrency(
                    cartController.grandTotal,
                  ),
                  strong: true,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
