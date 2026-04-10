import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_page_header.dart';
import '../controllers/inventory_products_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';
import '../widgets/inventory_cetaogry_filter.dart';

class InventoryProductsPage extends GetView<InventoryProductsController> {
  const InventoryProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                children: [
                  const AppPageHeader(title: 'Products'),
                  const SizedBox(height: 14),
                  InventorySearchPanel(
                    searchController: controller.searchTextController,
                    onSearchChanged: controller.onSearchChanged,
                    onClearSearch: controller.clearSearch,
                    hasActiveSearch: controller.hasActiveSearch,
                    isSearching: controller.isSearching.value,
                  ),
                  const SizedBox(height: 10),
                  InventoryCategoryFilterSection(
                    categories: controller.categories.toList(growable: false),
                    selectedCategoryId: controller.selectedCategoryId.value,
                    isLoading: controller.isCategoriesLoading.value,
                    hasActiveCategory: controller.hasActiveCategory,
                    onReset: controller.clearCategory,
                    onSelectCategory: controller.onCategoryChanged,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.retry,
                child: ListView(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    InventoryCatalogHeader(
                      totalProducts: controller.products.length,
                      hasActiveFilter: controller.hasActiveFilter,
                      selectedCategoryName:
                          controller.selectedCategoryId.value == null
                          ? null
                          : controller.categories
                                .firstWhereOrNull(
                                  (category) =>
                                      category.id ==
                                      controller.selectedCategoryId.value,
                                )
                                ?.name,
                      searchQuery: controller.searchQuery.value,
                      onClearFilters: controller.clearFilters,
                    ),
                    const SizedBox(height: 8),
                    if (controller.showInlineLoader)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (controller.isInitialLoading.value &&
                        controller.products.isEmpty)
                      const InventoryPageState(
                        icon: Icons.inventory_2_outlined,
                        message: 'Loading products',
                        isLoading: true,
                      )
                    else if (controller.hasErrorState)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: InventoryPageState(
                          icon: Icons.cloud_off_outlined,
                          message: controller.errorMessage.value!,
                          actionLabel: 'Retry',
                          onAction: controller.retry,
                        ),
                      )
                    else if (controller.hasEmptyState)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: InventoryPageState(
                          icon: Icons.inventory_2_outlined,
                          message:
                              controller.infoMessage.value ??
                              'No products found.',
                        ),
                      )
                    else
                      ...controller.products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InventoryProductCard(
                            product: product,
                            onTap: () => controller.openDetails(product),
                          ),
                        ),
                      ),
                    if (controller.isLoadingMore.value)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
