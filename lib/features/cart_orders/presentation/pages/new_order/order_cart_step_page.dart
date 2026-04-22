import 'package:flutter/material.dart';
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
            title: 'Intended delivery',
            subtitle:
                'Required planned delivery date and time shared with the customer.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => controller.pickIntendedDeliveryAt(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Delivery date and time',
                      prefixIcon: const Icon(Icons.schedule_outlined),
                      suffixIcon: const Icon(Icons.edit_calendar_outlined),
                      helperText:
                          cartController.selectedIntendedDeliveryAt.value ==
                              null
                          ? 'Required before draft save or confirm.'
                          : 'Tap to update the planned delivery time.',
                      helperStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                            color:
                                cartController
                                        .selectedIntendedDeliveryAt
                                        .value ==
                                    null
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                    child: Text(
                      cartController.formatIntendedDeliveryDisplay(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            cartController.selectedIntendedDeliveryAt.value ==
                                null
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            cartController.selectedIntendedDeliveryAt.value ==
                                null
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
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
