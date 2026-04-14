import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_purchase_controller.dart';
import '../models/purchase_draft_item.dart';
import '../widgets/inventory_catalog_widgets.dart';
import '../widgets/inventory_cetaogry_filter.dart';

class CreatePurchasePage extends GetView<CreatePurchaseController> {
  const CreatePurchasePage({super.key});

  Future<void> _openFiltersSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Obx(
        () => InventoryProductFilterSheet(
          categories: controller.categories.toList(growable: false),
          subcategories: controller.subcategories.toList(growable: false),
          initialCategoryId: controller.selectedCategoryId.value,
          initialSubcategoryId: controller.selectedSubcategoryId.value,
          initialStockStatus: controller.selectedStockStatus.value,
          isCategoriesLoading: controller.isCategoriesLoading.value,
          isSubcategoriesLoading: controller.isSubcategoriesLoading.value,
          onLoadSubcategories: controller.loadSubcategories,
          onApply: (categoryId, subcategoryId, stockStatus) {
            return controller.applyFilters(
              categoryId: categoryId,
              subcategoryId: subcategoryId,
              stockStatus: stockStatus,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Purchase')),
      body: SafeArea(
        child: Obx(() {
          final activeFilterCount =
              (controller.hasActiveCategory ? 1 : 0) +
              (controller.hasActiveSubcategory ? 1 : 0) +
              (controller.hasActiveStockStatus ? 1 : 0);

          return ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _PurchaseDraftCard(controller: controller),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.searchTextController,
                      onChanged: controller.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by product name, SKU, or barcode',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.hasActiveSearch
                            ? IconButton(
                                onPressed: controller.clearSearch,
                                icon: const Icon(Icons.close),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: controller.isResolvingBarcode.value
                        ? null
                        : controller.openScanner,
                    icon: controller.isResolvingBarcode.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InventoryProductFilterButton(
                    hasActiveFilter: controller.hasActiveFilter,
                    activeFilterCount: activeFilterCount,
                    onTap: () => _openFiltersSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (controller.hasActiveFilter)
                    TextButton(
                      onPressed: controller.clearFilters,
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (controller.isInitialLoading.value &&
                  controller.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.hasErrorState)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.errorMessage.value ??
                              'Unable to load products.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (controller.hasEmptyState)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(controller.emptyStateMessage),
                  ),
                )
              else
                ...controller.visibleProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InventoryProductCard(
                      product: product,
                      onTap: () => controller.openPurchaseDetails(product),
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
            () => FilledButton.icon(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitPurchase,
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                controller.draftItems.isEmpty
                    ? 'Save Purchase'
                    : 'Save Purchase (${controller.draftItems.length})',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseDraftCard extends StatelessWidget {
  const _PurchaseDraftCard({required this.controller});

  final CreatePurchaseController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase Draft',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add one or more product lines. Duplicate product and variant combinations are merged into a single line.',
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
                    controller.formatDate(controller.purchaseDate.value),
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
              if (controller.submitError.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.submitError.value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (controller.draftItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'No purchase lines yet. Select a product below or scan a barcode to add your first line.',
                  ),
                )
              else
                ...controller.draftItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DraftItemCard(
                      item: item,
                      formatCurrency: controller.formatCurrency,
                      onTap: item.product == null
                          ? null
                          : () => controller.openDraftItemEditor(item),
                      onRemove: () => controller.removeDraftItem(item.lineKey),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Draft total',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftItemCard extends StatelessWidget {
  const _DraftItemCard({
    required this.item,
    required this.formatCurrency,
    required this.onRemove,
    this.onTap,
  });

  final PurchaseDraftItem item;
  final String Function(num value) formatCurrency;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
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
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.barcode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove line',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if ((item.variantLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Variant: ${item.variantLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
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
                _LinePill(label: 'Qty', value: '${item.quantity}'),
                _LinePill(
                  label: 'Unit Cost',
                  value: formatCurrency(item.unitCost),
                ),
                _LinePill(
                  label: 'Line Total',
                  value: formatCurrency(item.totalAmount),
                ),
                _LinePill(label: 'Stock', value: '${item.currentStock}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePill extends StatelessWidget {
  const _LinePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
