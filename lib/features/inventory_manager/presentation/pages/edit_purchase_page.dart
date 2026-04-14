import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/edit_purchase_controller.dart';
import '../models/purchase_draft_item.dart';

class EditPurchasePage extends GetView<EditPurchaseController> {
  const EditPurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Purchase')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null &&
              controller.purchase.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.loadPurchase,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final purchase = controller.purchase.value;
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              if (controller.submitError.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    controller.submitError.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase?.purchaseNo?.isNotEmpty == true
                            ? purchase!.purchaseNo!
                            : 'Purchase #${purchase?.id ?? controller.purchaseId}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adjust purchase date, note, quantity, and unit cost without changing the existing update API.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                            controller.formatDisplayDate(
                              controller.purchaseDate.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Purchase Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...controller.draftItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EditablePurchaseItemCard(
                    item: item,
                    quantityController: controller.quantityControllerFor(
                      item.lineKey,
                    ),
                    unitCostController: controller.unitCostControllerFor(
                      item.lineKey,
                    ),
                    formatCurrency: controller.formatCurrency,
                    isSubmitting: controller.isSubmitting.value,
                    onRemove: () => controller.removeDraftItem(item.lineKey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Updated total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        controller.formatCurrency(controller.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
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
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Obx(
            () => FilledButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitUpdate,
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Purchase'),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditablePurchaseItemCard extends StatelessWidget {
  const _EditablePurchaseItemCard({
    required this.item,
    required this.quantityController,
    required this.unitCostController,
    required this.formatCurrency,
    required this.isSubmitting,
    required this.onRemove,
  });

  final PurchaseDraftItem item;
  final TextEditingController quantityController;
  final TextEditingController unitCostController;
  final String Function(num value) formatCurrency;
  final bool isSubmitting;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isSubmitting ? null : onRemove,
                  tooltip: 'Remove line',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.barcode,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if ((item.variantLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Variant: ${item.variantLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((item.optionValues ?? const <String, String>{}).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.optionValues!.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join('  •  '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ItemPill(label: 'SKU', value: item.sku),
                _ItemPill(label: 'Category', value: item.categoryName),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCostController,
                    enabled: !isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost',
                      prefixText: '৳',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ItemPill(
                  label: 'Line Total',
                  value: formatCurrency(item.totalAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPill extends StatelessWidget {
  const _ItemPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
