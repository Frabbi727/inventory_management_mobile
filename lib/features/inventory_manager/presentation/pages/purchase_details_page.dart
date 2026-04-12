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
      appBar: AppBar(title: const Text('Purchase Details')),
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
                        'Receiving Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => controller.pickDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            controller.formatDate(
                              controller.purchaseDate.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (controller.requiresVariantSelection) ...[
                        const SizedBox(height: 16),
                        if (controller.isVariantLoading.value)
                          const LinearProgressIndicator()
                        else
                          DropdownButtonFormField<int>(
                            initialValue: controller.selectedVariantId.value,
                            items: controller.activeVariants
                                .map(
                                  (variant) => DropdownMenuItem<int>(
                                    value: variant.id,
                                    child: Text(
                                      variant.combinationLabel ??
                                          variant.combinationKey ??
                                          'Variant ${variant.id ?? ''}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.onVariantChanged,
                            decoration: const InputDecoration(
                              labelText: 'Variant',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tune_rounded),
                            ),
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
                            if ((controller.selectedVariantLabel ?? '').isNotEmpty) ...[
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
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitPurchase,
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Purchase'),
            ),
          ),
        ),
      ),
    );
  }
}
