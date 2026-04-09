import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_product_picker_controller.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  static const _steps = ['Products', 'Review', 'Customer', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productPickerController = Get.find<OrderProductPickerController>();

    return SafeArea(
      child: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Order',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StepHeader(
                    currentStep: controller.currentStep.value,
                    onStepTap: controller.goToStep,
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Padding(
                  key: ValueKey(controller.currentStep.value),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildStepBody(
                    context,
                    controller.currentStep.value,
                    productPickerController,
                  ),
                ),
              ),
            ),
            if (controller.errorMessage.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ErrorBanner(message: controller.errorMessage.value!),
              ),
            _StepActions(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(
    BuildContext context,
    int step,
    OrderProductPickerController productPickerController,
  ) {
    switch (step) {
      case 0:
        return _ProductsStep(
          cartController: controller,
          productController: productPickerController,
        );
      case 1:
        return _ReviewStep(controller: controller);
      case 2:
        return _CustomerStep(
          customer: controller.selectedCustomer.value,
          onSearchCustomer: () => _pickCustomer(context),
          onAddCustomer: () => _addCustomer(context),
        );
      default:
        return _ConfirmStep(controller: controller);
    }
  }

  Future<void> _pickCustomer(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Get.toNamed(AppRoutes.customerSearch);
    if (result is CustomerModel) {
      controller.setSelectedCustomer(result);
      messenger.showSnackBar(
        SnackBar(content: Text('${result.name ?? 'Customer'} selected')),
      );
    }
  }

  Future<void> _addCustomer(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Get.toNamed(AppRoutes.addCustomer);
    if (result is CustomerModel) {
      controller.setSelectedCustomer(result);
      messenger.showSnackBar(
        SnackBar(content: Text('${result.name ?? 'Customer'} added')),
      );
    }
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep, required this.onStepTap});

  final int currentStep;
  final void Function(int step) onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(CartPage._steps.length, (index) {
        final title = CartPage._steps[index];
        final selected = currentStep == index;
        final completed = currentStep > index;

        return Expanded(
          child: InkWell(
            onTap: () => onStepTap(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: EdgeInsets.only(
                right: index == CartPage._steps.length - 1 ? 0 : 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: completed
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: completed || selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    child: Icon(
                      completed ? Icons.check : Icons.circle,
                      size: 14,
                      color: completed || selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${index + 1}. $title',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ProductsStep extends StatelessWidget {
  const _ProductsStep({
    required this.cartController,
    required this.productController,
  });

  final CartController cartController;
  final OrderProductPickerController productController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _StepCard(
          title: 'Step 1: Add Products',
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Items',
                  value: '${cartController.totalUnits}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Subtotal',
                  value: cartController.formatCurrency(cartController.subtotal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SearchBar(
          controller: productController.searchController,
          hintText: 'Search by product name or SKU',
          leading: const Icon(Icons.search),
          onChanged: productController.onSearchChanged,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (productController.infoMessage.value == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                productController.infoMessage.value!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            if (productController.isInitialLoading.value &&
                productController.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productController.errorMessage.value != null &&
                productController.products.isEmpty) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                message: productController.errorMessage.value!,
                actionLabel: 'Retry',
                onAction: productController.retry,
              );
            }

            if (productController.products.isEmpty) {
              return _MessageState(
                icon: Icons.inventory_2_outlined,
                message:
                    productController.infoMessage.value ??
                    'No products available.',
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
                  final stock = product.currentStock ?? 0;
                  final selectedItem = cartController.itemByProductId(
                    product.id,
                  );

                  return _ProductPickerCard(
                    product: product,
                    formattedPrice: productController.formatPrice(
                      product.sellingPrice,
                    ),
                    selectedQuantity: selectedItem?.quantity ?? 0,
                    stock: stock,
                    onAdd: () =>
                        _handleAddProduct(context, cartController, product),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  void _handleAddProduct(
    BuildContext context,
    CartController controller,
    ProductModel product,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final added = controller.addProduct(product);

    if (!added) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            (product.currentStock ?? 0) <= 0
                ? '${product.name ?? 'Product'} is out of stock.'
                : 'Available stock limit reached for ${product.name ?? 'this product'}.',
          ),
        ),
      );
      return;
    }
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepCard(
          title: 'Step 2: Review',
          child: Column(
            children: [
              for (final item in controller.items)
                Padding(
                  key: ValueKey(
                    'cart-item-${item.productId ?? item.product.sku ?? item.product.name}',
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SimpleCartTile(
                    item: item,
                    formatCurrency: controller.formatCurrency,
                    canIncrement: controller.canIncrementQuantity(
                      item.productId,
                    ),
                    onIncrement: () =>
                        controller.incrementQuantity(item.productId),
                    onDecrement: () =>
                        controller.decrementQuantity(item.productId),
                    onRemove: () => controller.removeItem(item.productId),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ReviewRow(
                      label: 'Subtotal',
                      value: controller.formatCurrency(controller.subtotal),
                    ),
                    const SizedBox(height: 12),
                    _ReviewRow(
                      label: 'Units',
                      value: '${controller.totalUnits}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Discount',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
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
                    selected: controller.discountType.value == 'percent',
                    onSelected: (_) => controller.setDiscountType('percent'),
                  ),
                ],
              ),
              if (controller.discountType.value != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller.discountValueController,
                  onChanged: controller.onDiscountValueChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: controller.discountType.value == 'percent'
                        ? 'Discount percent'
                        : 'Discount amount',
                  ),
                ),
              ],
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
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerStep extends StatelessWidget {
  const _CustomerStep({
    required this.customer,
    required this.onSearchCustomer,
    required this.onAddCustomer,
  });

  final CustomerModel? customer;
  final VoidCallback onSearchCustomer;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepCard(
          title: 'Step 3: Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer == null)
                const _HintBox(
                  icon: Icons.person_search_outlined,
                  text: 'Choose the customer for this order.',
                )
              else
                _CustomerPreview(customer: customer!),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onSearchCustomer,
                    icon: const Icon(Icons.search),
                    label: Text(
                      customer == null ? 'Select Customer' : 'Change Customer',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddCustomer,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepCard(
          title: 'Step 4: Confirm',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.selectedCustomer.value != null) ...[
                Text(
                  'Customer',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _CustomerPreview(customer: controller.selectedCustomer.value!),
                const SizedBox(height: 16),
              ],
              Text(
                'Items',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final item in controller.items)
                Padding(
                  key: ValueKey('confirm-item-${item.productId}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ConfirmItemTile(
                    item: item,
                    formatCurrency: controller.formatCurrency,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ReviewRow(
                      label: 'Subtotal',
                      value: controller.formatCurrency(controller.subtotal),
                    ),
                    const SizedBox(height: 12),
                    _ReviewRow(
                      label: 'Discount',
                      value: controller.formatCurrency(
                        controller.estimatedDiscountAmount,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReviewRow(
                      label: 'Grand total',
                      value: controller.formatCurrency(controller.grandTotal),
                      strong: true,
                    ),
                  ],
                ),
              ),
              if (controller.noteController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Note',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(controller.noteController.text.trim()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepActions extends StatelessWidget {
  const _StepActions({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final isLastStep = controller.currentStep.value == 3;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (controller.currentStep.value > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (controller.currentStep.value > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : isLastStep
                    ? controller.submitOrder
                    : controller.nextStep,
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(controller.submitButtonLabel()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.title, required this.child});

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
              style: theme.textTheme.titleLarge?.copyWith(
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerCard extends StatelessWidget {
  const _ProductPickerCard({
    required this.product,
    required this.formattedPrice,
    required this.selectedQuantity,
    required this.stock,
    required this.onAdd,
  });

  final ProductModel product;
  final String formattedPrice;
  final int selectedQuantity;
  final int stock;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final lowStock = stock <= 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unnamed product',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(product.sku ?? '-'),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: stock <= 0 ? null : onAdd,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniChip(label: 'Price', value: formattedPrice),
                _MiniChip(
                  label: 'Stock',
                  value: '$stock',
                  highlighted: lowStock,
                ),
                if (selectedQuantity > 0)
                  _MiniChip(
                    label: 'In order',
                    value: '$selectedQuantity',
                    highlighted: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _CustomerPreview extends StatelessWidget {
  const _CustomerPreview({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name ?? '-',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(customer.phone ?? '-'),
          if ((customer.address ?? '').isNotEmpty) Text(customer.address!),
          if ((customer.area ?? '').isNotEmpty) Text(customer.area!),
        ],
      ),
    );
  }
}

class _SimpleCartTile extends StatelessWidget {
  const _SimpleCartTile({
    required this.item,
    required this.formatCurrency,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItemModel item;
  final String Function(num? value) formatCurrency;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name ?? 'Unnamed product',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onRemove, child: const Text('Remove')),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.product.sku ?? '-'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Price: ${formatCurrency(item.unitPrice)}'),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onDecrement,
                      icon: const Icon(Icons.remove),
                      tooltip: 'Decrease quantity',
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: canIncrement ? onIncrement : null,
                      icon: const Icon(Icons.add),
                      tooltip: 'Increase quantity',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmItemTile extends StatelessWidget {
  const _ConfirmItemTile({required this.item, required this.formatCurrency});

  final CartItemModel item;
  final String Function(num? value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name ?? 'Unnamed product',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('${item.quantity} x ${formatCurrency(item.unitPrice)}'),
              ],
            ),
          ),
          Text(
            formatCurrency(item.lineTotal),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
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

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
