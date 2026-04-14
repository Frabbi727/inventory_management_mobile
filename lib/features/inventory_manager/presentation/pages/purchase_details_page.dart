import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/purchase_details_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';

class PurchaseDetailsPage extends GetView<PurchaseDetailsController> {
  const PurchaseDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Item')),
      body: SafeArea(
        child: Obx(() {
          final product = controller.product.value;
          if (product == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.submitError.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    controller.submitError.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unnamed product',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InventoryInfoChip(
                            label: 'SKU',
                            value: product.sku ?? '-',
                          ),
                          InventoryInfoChip(
                            label: 'Barcode',
                            value: product.barcode ?? '-',
                          ),
                          InventoryInfoChip(
                            label: 'Stock',
                            value: '${product.currentStock ?? 0}',
                          ),
                          if (product.subcategory?.name != null)
                            InventoryInfoChip(
                              label: 'Subcategory',
                              value: product.subcategory!.name!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Line',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.requiresVariantSelection
                            ? 'Choose the specific variant and enter the quantity and unit cost for this line.'
                            : 'Enter the quantity and unit cost for this simple product line.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (controller.requiresVariantSelection) ...[
                        const SizedBox(height: 16),
                        if (controller.isVariantLoading.value)
                          const LinearProgressIndicator()
                        else if (!controller.hasSelectableVariants)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'This product has variants, but no active variant is available for receiving.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Variant',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...controller.activeVariants.map(
                                (variant) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _VariantChoiceCard(
                                    label:
                                        variant.resolvedLabel ??
                                        variant.combinationKey ??
                                        'Variant ${variant.id ?? ''}',
                                    stock: variant.currentStock ?? 0,
                                    purchasePrice: variant.purchasePrice,
                                    optionValues:
                                        variant.optionValues ??
                                        const <String, String>{},
                                    isSelected:
                                        controller.selectedVariantId.value ==
                                        variant.id,
                                    onTap: () =>
                                        controller.onVariantChanged(variant.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: controller.decreaseQuantity,
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controller.quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: const OutlineInputBorder(),
                                errorText: controller.quantityError.value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            onPressed: controller.increaseQuantity,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.unitCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Unit Cost',
                          prefixText: '৳',
                          border: const OutlineInputBorder(),
                          errorText: controller.unitCostError.value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '৳${controller.totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if ((controller.selectedVariantLabel ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                controller.selectedVariantLabel!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Obx(
            () => FilledButton(
              onPressed: controller.submitLine,
              child: Text(
                controller.initialItem.value == null
                    ? 'Add Purchase Line'
                    : 'Update Purchase Line',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantChoiceCard extends StatelessWidget {
  const _VariantChoiceCard({
    required this.label,
    required this.stock,
    this.purchasePrice,
    required this.optionValues,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int stock;
  final num? purchasePrice;
  final Map<String, String> optionValues;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (optionValues.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        optionValues.entries
                            .map((entry) => '${entry.key}: ${entry.value}')
                            .join('  •  '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  purchasePrice == null
                      ? 'Stock $stock'
                      : 'Stock $stock • Buy ৳${_formatPrice(purchasePrice!)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
