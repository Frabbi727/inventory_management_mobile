import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/navigation/app_route_observer.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../controllers/inventory_products_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        return RefreshIndicator(
          onRefresh: controller.retry,
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppPageHeader(
                title: 'Products',
                trailing: FilledButton.icon(
                  onPressed: controller.openManualCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product'),
                ),
              ),
              const SizedBox(height: 10),
              InventorySearchPanel(
                searchController: controller.searchTextController,
                onSearchChanged: controller.onSearchChanged,
                onClearSearch: controller.clearSearch,
                hasActiveSearch: controller.hasActiveSearch,
                isSearching: controller.isSearching.value,
              ),
              const SizedBox(height: 8),
              _SummaryCardGrid(controller: controller),
              const SizedBox(height: 8),
              // _TodayActivityRow(controller: controller),
              // const SizedBox(height: 10),
              InventoryCatalogHeader(
                totalProducts: controller.totalProducts.value,
                hasActiveFilter: controller.hasActiveFilter,
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
                  controller.summary.value == null &&
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
                  child: AppMessageState(
                    icon: Icons.inventory_2_outlined,
                    message:
                        controller.infoMessage.value ??
                        controller.buildEmptyMessage(),
                    actionLabel: controller.hasActiveSearch
                        ? 'Clear search'
                        : 'Refresh',
                    onAction: controller.hasActiveSearch
                        ? () async => controller.clearSearch()
                        : controller.retry,
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
        );
      }),
    );
  }
}

class _SummaryCardGrid extends StatelessWidget {
  const _SummaryCardGrid({required this.controller});

  final InventoryProductsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.9,
          children: [
            _SummaryCard(
              label: 'All Products',
              value: '${controller.countForStatus(null)}',
              accentColor: const Color(0xFF0F766E),
              backgroundColor: const Color(0xFFF3FBFA),
              isSelected: controller.selectedStockStatus.value == null,
              onTap: () => controller.applyStockFilter(null),
            ),
            _SummaryCard(
              label: 'In Stock',
              value: '${controller.countForStatus(ProductStockStatus.inStock)}',
              accentColor: const Color(0xFF15803D),
              backgroundColor: const Color(0xFFF2FBF5),
              isSelected:
                  controller.selectedStockStatus.value == ProductStockStatus.inStock,
              onTap: () =>
                  controller.applyStockFilter(ProductStockStatus.inStock),
            ),
            _SummaryCard(
              label: 'Low Stock',
              value: '${controller.countForStatus(ProductStockStatus.lowStock)}',
              accentColor: const Color(0xFFC2410C),
              backgroundColor: const Color(0xFFFFF7ED),
              isSelected:
                  controller.selectedStockStatus.value == ProductStockStatus.lowStock,
              onTap: () =>
                  controller.applyStockFilter(ProductStockStatus.lowStock),
            ),
            _SummaryCard(
              label: 'Out of Stock',
              value: '${controller.countForStatus(ProductStockStatus.outOfStock)}',
              accentColor: const Color(0xFFB91C1C),
              backgroundColor: const Color(0xFFFEF2F2),
              isSelected:
                  controller.selectedStockStatus.value ==
                  ProductStockStatus.outOfStock,
              onTap: () =>
                  controller.applyStockFilter(ProductStockStatus.outOfStock),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayActivityRow extends StatelessWidget {
  const _TodayActivityRow({required this.controller});

  final InventoryProductsController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary.value;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        InventoryMetaPill(
          label: 'Added Today',
          value: '${summary?.productsAddedToday ?? 0}',
        ),
        InventoryMetaPill(
          label: 'Purchases Today',
          value: '${summary?.purchasesCreatedToday ?? 0}',
        ),
        InventoryMetaPill(
          label: 'Purchase Value',
          value: controller.formatCurrency(summary?.purchaseValueToday),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color accentColor;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? backgroundColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? accentColor : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
