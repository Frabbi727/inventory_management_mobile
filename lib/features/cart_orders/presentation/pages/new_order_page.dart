import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/order_flow_widgets.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  static const _steps = ['Customer', 'Products', 'Cart', 'Confirm'];

  late final CartController controller;
  late final CustomerSearchController customerController;
  late final ProductListController productController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CartController>();
    customerController = Get.find<CustomerSearchController>();
    productController = Get.find<ProductListController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('New Order')),
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    StepperWidget(
                      steps: _steps,
                      currentStep: controller.currentStep.value,
                      onStepTap: controller.goToStep,
                    ),
                    if (controller.errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineWarningBanner(
                        message: controller.errorMessage.value!,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Padding(
                    key: ValueKey(controller.currentStep.value),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: switch (controller.currentStep.value) {
                      CartController.customerStep => _CustomerStep(
                        cartController: controller,
                        customerController: customerController,
                      ),
                      CartController.productsStep => _ProductsStep(
                        cartController: controller,
                        productController: productController,
                      ),
                      CartController.cartStep => _CartStep(
                        controller: controller,
                      ),
                      _ => _ConfirmStep(controller: controller),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => SummaryFooter(
          subtotal: controller.showFooterTotals
              ? controller.formatCurrency(controller.subtotal)
              : null,
          total: controller.showFooterTotals
              ? controller.formatCurrency(controller.grandTotal)
              : null,
          showTotals: controller.showFooterTotals,
          primaryLabel: _primaryLabel(controller.currentStep.value),
          secondaryLabel:
              controller.currentStep.value == CartController.customerStep
              ? null
              : 'Back',
          onSecondaryPressed:
              controller.currentStep.value == CartController.customerStep
              ? null
              : controller.previousStep,
          isLoading: controller.isSubmitting.value,
          onPrimaryPressed: () async {
            if (controller.currentStep.value == CartController.confirmStep) {
              await controller.submitOrder();
              return;
            }

            controller.nextStep();
          },
        ),
      ),
    );
  }

  String _primaryLabel(int step) {
    if (step == CartController.cartStep) {
      return 'Confirm Order';
    }

    return controller.submitButtonLabel();
  }
}

class _CustomerStep extends StatelessWidget {
  const _CustomerStep({
    required this.cartController,
    required this.customerController,
  });

  final CartController cartController;
  final CustomerSearchController customerController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () => Column(
        children: [
          if (cartController.selectedCustomer.value != null) ...[
            CustomerTile(
              customerName: cartController.selectedCustomer.value!.name ?? '-',
              phone: cartController.selectedCustomer.value!.phone ?? '-',
              address: cartController.selectedCustomer.value!.address ?? '-',
              area: cartController.selectedCustomer.value!.area,
              trailing: FilledButton.tonal(
                onPressed: () => cartController.setSelectedCustomer(null),
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SearchBar(
            controller: customerController.searchController,
            hintText: 'Search by name or phone',
            leading: Icon(Icons.search, color: theme.colorScheme.primary),
            backgroundColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.96),
            ),
            elevation: const WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onChanged: customerController.onSearchChanged,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addCustomer);
                if (result is CustomerModel) {
                  cartController.setSelectedCustomer(result);
                  await customerController.retry();
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Customer'),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (customerController.isInitialLoading.value &&
                    customerController.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (customerController.errorMessage.value != null &&
                    customerController.customers.isEmpty) {
                  return AppMessageState(
                    icon: Icons.cloud_off_outlined,
                    message: customerController.errorMessage.value!,
                    actionLabel: 'Retry',
                    onAction: customerController.retry,
                  );
                }

                if (customerController.customers.isEmpty) {
                  return AppMessageState(
                    icon: Icons.person_search_outlined,
                    message:
                        customerController.infoMessage.value ??
                        'No customers are available right now.',
                    actionLabel: 'Refresh',
                    onAction: customerController.retry,
                  );
                }

                return RefreshIndicator(
                  onRefresh: customerController.retry,
                  child: ListView.separated(
                    controller: customerController.scrollController,
                    itemCount:
                        customerController.customers.length +
                        (customerController.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= customerController.customers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final customer = customerController.customers[index];
                      final isSelected =
                          cartController.selectedCustomer.value?.id ==
                          customer.id;

                      return CustomerTile(
                        customerName: customer.name ?? 'Unnamed customer',
                        phone: customer.phone ?? '-',
                        address: customer.address ?? '-',
                        area: customer.area,
                        onTap: () =>
                            cartController.setSelectedCustomer(customer),
                        trailing: FilledButton.tonal(
                          onPressed: () =>
                              cartController.setSelectedCustomer(customer),
                          child: Text(isSelected ? 'Selected' : 'Select'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsStep extends StatelessWidget {
  const _ProductsStep({
    required this.cartController,
    required this.productController,
  });

  final CartController cartController;
  final ProductListController productController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SearchBar(
          controller: productController.searchController,
          hintText: 'Search by product name or SKU',
          leading: Icon(Icons.search, color: theme.colorScheme.primary),
          backgroundColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.96),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          onChanged: productController.onSearchChanged,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            final _ = cartController.items.length;

            if (productController.isInitialLoading.value &&
                productController.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productController.errorMessage.value != null &&
                productController.products.isEmpty) {
              return AppMessageState(
                icon: Icons.cloud_off_outlined,
                message: productController.errorMessage.value!,
                actionLabel: 'Retry',
                onAction: productController.retry,
              );
            }

            if (productController.products.isEmpty) {
              return AppMessageState(
                icon: Icons.inventory_2_outlined,
                message:
                    productController.infoMessage.value ??
                    'No products are available right now.',
                actionLabel: 'Refresh',
                onAction: productController.retry,
              );
            }

            return RefreshIndicator(
              onRefresh: productController.retry,
              child: ListView.separated(
                controller: productController.scrollController,
                itemCount:
                    productController.products.length +
                    (productController.isLoadingMore.value ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= productController.products.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final product = productController.products[index];
                  final cartItem = cartController.itemByProductId(product.id);

                  return ProductCard(
                    name: product.name ?? 'Unnamed product',
                    sku: product.sku ?? '-',
                    price: productController.formatPrice(product.sellingPrice),
                    stock: product.currentStock ?? 0,
                    selectedQuantity: cartItem?.quantity ?? 0,
                    onAdd: () => cartController.addProduct(product),
                    onIncrement: () =>
                        cartController.incrementQuantity(product.id),
                    onDecrement: () =>
                        cartController.decrementQuantity(product.id),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CartStep extends StatelessWidget {
  const _CartStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.items.isEmpty) {
        return AppMessageState(
          icon: Icons.shopping_bag_outlined,
          message:
              'Your cart is empty. Add products before confirming the order.',
          actionLabel: 'Back to Products',
          onAction: () async =>
              controller.goToStep(CartController.productsStep),
        );
      }

      final customer = controller.selectedCustomer.value;

      return ListView(
        children: [
          if (customer != null) ...[
            CustomerTile(
              customerName: customer.name ?? '-',
              phone: customer.phone ?? '-',
              address: customer.address ?? '-',
              area: customer.area,
            ),
            const SizedBox(height: 12),
          ],
          for (final item in controller.items) ...[
            CartItemWidget(
              title: item.product.name ?? 'Unnamed product',
              subtitle: item.product.sku ?? '-',
              quantity: item.quantity,
              unitPrice: controller.formatCurrency(item.unitPrice),
              lineTotal: controller.formatCurrency(item.lineTotal),
              canIncrement: controller.canIncrementQuantity(item.productId),
              onIncrement: () => controller.incrementQuantity(item.productId),
              onDecrement: () => controller.decrementQuantity(item.productId),
              onRemove: () => controller.removeItem(item.productId),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller.discountValueController,
            enabled: controller.isDiscountEnabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
            onChanged: controller.onDiscountValueChanged,
            onEditingComplete: () {
              controller.normalizeDiscountInputText();
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: controller.discountType.value == 'percentage'
                  ? 'Discount percent'
                  : 'Discount amount',
              hintText: controller.discountType.value == null
                  ? 'Select discount type first'
                  : '0.00',
              helperText: controller.discountType.value == 'percentage'
                  ? 'Allowed range: 0.00% to 100.00%'
                  : 'Enter a fixed discount amount',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('None'),
                selected: controller.discountType.value == null,
                onSelected: (_) => controller.setDiscountType(null),
              ),
              ChoiceChip(
                label: const Text('Amount'),
                selected: controller.discountType.value == 'amount',
                onSelected: (_) => controller.setDiscountType('amount'),
              ),
              ChoiceChip(
                label: const Text('Percent'),
                selected: controller.discountType.value == 'percentage',
                onSelected: (_) => controller.setDiscountType('percentage'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Optional delivery or order note',
            ),
          ),
          const SizedBox(height: 120),
        ],
      );
    });
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customer = controller.selectedCustomer.value;

      return ListView(
        children: [
          if (customer != null) ...[
            CustomerTile(
              customerName: customer.name ?? '-',
              phone: customer.phone ?? '-',
              address: customer.address ?? '-',
              area: customer.area,
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.items.isEmpty)
                    const Text('No products selected yet.')
                  else
                    for (final item in controller.items) ...[
                      _ConfirmRow(
                        title: item.product.name ?? 'Unnamed product',
                        subtitle:
                            '${item.quantity} x ${controller.formatCurrency(item.unitPrice)}',
                        value: controller.formatCurrency(item.lineTotal),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TotalRow(
                    label: 'Subtotal',
                    value: controller.formatCurrency(controller.subtotal),
                  ),
                  const SizedBox(height: 12),
                  _TotalRow(
                    label: 'Discount',
                    value: controller.formatCurrency(
                      controller.estimatedDiscountAmount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TotalRow(
                    label: 'Total',
                    value: controller.formatCurrency(controller.grandTotal),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const InlineWarningBanner(
            message:
                'Final total will be confirmed by the server after the order is submitted.',
          ),
          if (controller.noteText.value.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(controller.noteText.value.trim()),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 120),
        ],
      );
    });
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: style),
      ],
    );
  }
}
