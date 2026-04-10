import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_purchase_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';

class CreatePurchasePage extends GetView<CreatePurchaseController> {
  const CreatePurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
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
                InventoryCategoryFilterSection(
                  categories: controller.categories.toList(growable: false),
                  selectedCategoryId: controller.selectedCategoryId.value,
                  isLoading: controller.isCategoriesLoading.value,
                  hasActiveCategory: controller.hasActiveCategory,
                  onReset: controller.clearCategory,
                  onSelectCategory: controller.onCategoryChanged,
                  compact: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
                else if (controller.products.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No products found for the current search and category filters.',
                      ),
                    ),
                  )
                else
                  ...controller.products.map(
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
          ),
        ),
      ),
    );
  }
}
