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
      child: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  AppPageHeader(
                    title: 'Products',
                    trailing: FilledButton.icon(
                      onPressed: controller.openManualCreate,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  _ResultsBar(controller: controller),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (controller.showInlineLoader)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.retry,
                child: _InventoryProductsList(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryProductsList extends StatelessWidget {
  const _InventoryProductsList({required this.controller});

  final InventoryProductsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isInitialLoading.value &&
        controller.summary.value == null &&
        controller.products.isEmpty) {
      return ListView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
        children: const [
          InventoryPageState(
            icon: Icons.inventory_2_outlined,
            message: 'Loading products',
            isLoading: true,
          ),
        ],
      );
    }

    if (controller.hasErrorState) {
      return ListView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
        children: [
          InventoryPageState(
            icon: Icons.cloud_off_outlined,
            message: controller.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: controller.retry,
          ),
        ],
      );
    }

    if (controller.hasEmptyState) {
      return ListView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
        children: [
          AppMessageState(
            icon: Icons.inventory_2_outlined,
            message:
                controller.infoMessage.value ?? controller.buildEmptyMessage(),
            actionLabel: controller.hasActiveSearch ? 'Clear search' : 'Refresh',
            onAction: controller.hasActiveSearch
                ? () async => controller.clearSearch()
                : controller.retry,
          ),
        ],
      );
    }

    return ListView.builder(
      controller: controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
      itemCount:
          controller.products.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= controller.products.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final product = controller.products[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == controller.products.length - 1 ? 0 : 10,
          ),
          child: InventoryProductCard(
            product: product,
            onTap: () => controller.openDetails(product),
          ),
        );
      },
    );
  }
}

class _SummaryCardGrid extends StatelessWidget {
  const _SummaryCardGrid({required this.controller});

  final InventoryProductsController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.25,
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
          onTap: () => controller.applyStockFilter(ProductStockStatus.inStock),
        ),
        _SummaryCard(
          label: 'Low Stock',
          value: '${controller.countForStatus(ProductStockStatus.lowStock)}',
          accentColor: const Color(0xFFC2410C),
          backgroundColor: const Color(0xFFFFF7ED),
          isSelected:
              controller.selectedStockStatus.value == ProductStockStatus.lowStock,
          onTap: () => controller.applyStockFilter(ProductStockStatus.lowStock),
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
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.controller});

  final InventoryProductsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        controller.selectedStockStatus.value?.displayLabel ?? 'All Products';

    return Row(
      children: [
        Expanded(
          child: Text(
            '$label • ${controller.totalProducts.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (controller.hasActiveFilter)
          TextButton(
            onPressed: controller.clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Reset'),
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? backgroundColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.3 : 1,
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
              const SizedBox(width: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
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
