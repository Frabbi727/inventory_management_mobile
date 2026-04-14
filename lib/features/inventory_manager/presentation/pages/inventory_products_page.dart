import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/navigation/app_route_observer.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../controllers/inventory_products_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';
import '../widgets/inventory_cetaogry_filter.dart';

class InventoryProductsPage extends StatefulWidget {
  const InventoryProductsPage({super.key});

  @override
  State<InventoryProductsPage> createState() => _InventoryProductsPageState();
}

class _InventoryProductsPageState extends State<InventoryProductsPage>
    with RouteAware {
  late final InventoryProductsController controller;
  ModalRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    controller = Get.find<InventoryProductsController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      if (_subscribedRoute is PageRoute) {
        appRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (_subscribedRoute is PageRoute) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    controller.ensureLoaded(forceRefresh: true);
  }

  Future<void> _openFiltersSheet() async {
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
    return SafeArea(
      child: Obx(() {
        final activeFilterCount =
            (controller.hasActiveCategory ? 1 : 0) +
            (controller.hasActiveSubcategory ? 1 : 0) +
            (controller.hasActiveStockStatus ? 1 : 0);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                children: [
                  AppPageHeader(
                    title: 'Products',
                    trailing: FilledButton.icon(
                      onPressed: controller.openManualCreate,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Product'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InventorySearchPanel(
                    searchController: controller.searchTextController,
                    onSearchChanged: controller.onSearchChanged,
                    onClearSearch: controller.clearSearch,
                    hasActiveSearch: controller.hasActiveSearch,
                    isSearching: controller.isSearching.value,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InventoryProductFilterButton(
                        hasActiveFilter: controller.hasActiveFilter,
                        activeFilterCount: activeFilterCount,
                        onTap: _openFiltersSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      totalProducts: controller.visibleProducts.length,
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
                      selectedSubcategoryName:
                          controller.selectedSubcategoryId.value == null
                          ? null
                          : controller.subcategories
                                .firstWhereOrNull(
                                  (subcategory) =>
                                      subcategory.id ==
                                      controller.selectedSubcategoryId.value,
                                )
                                ?.name,
                      selectedStockStatusLabel:
                          controller.selectedStockStatus.value?.displayLabel,
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
                          message: controller.emptyStateMessage,
                        ),
                      )
                    else
                      ...controller.visibleProducts.map(
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
        );
      }),
    );
  }
}
