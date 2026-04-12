import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_purchase_controller.dart';
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
      appBar: AppBar(title: const Text('Purchases')),
      body: SafeArea(
        child: Obx(() {
          final activeFilterCount =
              (controller.hasActiveCategory ? 1 : 0) +
              (controller.hasActiveSubcategory ? 1 : 0) +
              (controller.hasActiveStockStatus ? 1 : 0);

          return RefreshIndicator(
            onRefresh: controller.retry,
            child: ListView(
              controller: controller.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
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
                        'Products',
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
            ),
          );
        }),
      ),
    );
  }
}
