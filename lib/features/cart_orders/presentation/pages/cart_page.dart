import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/home_controller.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../data/models/cart_item_model.dart';
import '../controllers/cart_controller.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  static const _steps = ['Customer', 'Products', 'Review'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: _buildStepBody(context, controller.currentStep.value),
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

  Widget _buildStepBody(BuildContext context, int step) {
    switch (step) {
      case 0:
        return _CustomerStep(
          customer: controller.selectedCustomer.value,
          onSearchCustomer: () => _pickCustomer(context),
          onAddCustomer: () => _addCustomer(context),
        );
      case 1:
        return _ProductsStep(
          items: controller.items,
          formatCurrency: controller.formatCurrency,
          onBrowseProducts: _goToProducts,
          canIncrement: controller.canIncrementQuantity,
          onIncrement: controller.incrementQuantity,
          onDecrement: controller.decrementQuantity,
          onRemove: controller.removeItem,
        );
      default:
        return _ReviewStep(controller: controller);
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

  void _goToProducts() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(0);
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
          title: 'Step 1: Customer',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer == null)
                const _HintBox(
                  icon: Icons.person_search_outlined,
                  text:
                      'Start by choosing an existing customer. If you cannot find them, add a new one.',
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
                    label: const Text('Search Customer'),
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

class _ProductsStep extends StatelessWidget {
  const _ProductsStep({
    required this.items,
    required this.formatCurrency,
    required this.onBrowseProducts,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final List<CartItemModel> items;
  final String Function(num? value) formatCurrency;
  final VoidCallback onBrowseProducts;
  final bool Function(int? productId) canIncrement;
  final bool Function(int? productId) onIncrement;
  final void Function(int? productId) onDecrement;
  final void Function(int? productId) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepCard(
          title: 'Step 2: Products',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.tonalIcon(
                onPressed: onBrowseProducts,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Open Products Tab'),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _HintBox(
                  icon: Icons.shopping_bag_outlined,
                  text:
                      'No product has been added yet. Open the Products tab, add items, then come back here.',
                )
              else
                Column(
                  children: items
                      .map(
                        (item) => Padding(
                          key: ValueKey(
                            'cart-item-${item.productId ?? item.product.sku ?? item.product.name}',
                          ),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SimpleCartTile(
                            item: item,
                            formatCurrency: formatCurrency,
                            canIncrement: canIncrement(item.productId),
                            onIncrement: () => onIncrement(item.productId),
                            onDecrement: () => onDecrement(item.productId),
                            onRemove: () => onRemove(item.productId),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
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
          title: 'Step 3: Review',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(
                label: 'Customer',
                value: controller.selectedCustomer.value?.name ?? '-',
              ),
              const SizedBox(height: 12),
              _ReviewRow(
                label: 'Items',
                value: '${controller.totalUnits} units',
              ),
              const SizedBox(height: 12),
              _ReviewRow(
                label: 'Subtotal',
                value: controller.formatCurrency(controller.subtotal),
              ),
              const SizedBox(height: 16),
              Text(
                'Discount',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
              const SizedBox(height: 16),
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
                      label: 'Estimated discount',
                      value: controller.formatCurrency(
                        controller.estimatedDiscountAmount,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReviewRow(
                      label: 'Estimated grand total',
                      value: controller.formatCurrency(controller.grandTotal),
                      strong: true,
                    ),
                  ],
                ),
              ),
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
    final isLastStep = controller.currentStep.value == 2;

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
              child: FilledButton.icon(
                onPressed: controller.isSubmitting.value
                    ? null
                    : isLastStep
                    ? controller.submitOrder
                    : controller.nextStep,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isLastStep
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                      ),
                label: Text(controller.submitButtonLabel()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
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
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
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
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
