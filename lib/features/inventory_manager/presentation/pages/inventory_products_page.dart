import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../controllers/inventory_products_controller.dart';
import '../widgets/inventory_catalog_widgets.dart';

class InventoryProductsPage extends GetView<InventoryProductsController> {
  const InventoryProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Obx(
        () => RefreshIndicator(
          onRefresh: controller.retry,
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppPageHeader(
                title: 'Products',
                subtitle:
                    'Scan first, then review product details or update stock-facing information.',
                trailing: FilledButton.icon(
                  onPressed: controller.openScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InventoryQuickActionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan Barcode',
                      subtitle: 'Find an item or start a new product.',
                      onTap: controller.openScan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InventoryQuickActionCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Low Stock',
                      subtitle: 'Review products below the minimum threshold.',
                      onTap: controller.openLowStock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.searchTextController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, or barcode',
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
              const SizedBox(height: 12),
              InventoryCategoryFilterSection(
                categories: controller.categories.toList(growable: false),
                selectedCategoryId: controller.selectedCategoryId.value,
                isLoading: controller.isCategoriesLoading.value,
                hasActiveCategory: controller.hasActiveCategory,
                onReset: controller.clearCategory,
                onSelectCategory: controller.onCategoryChanged,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (controller.hasActiveFilter)
                    TextButton(
                      onPressed: controller.clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (controller.isInitialLoading.value &&
                  controller.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.hasErrorState)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AppMessageState(
                    icon: Icons.cloud_off_outlined,
                    message: controller.errorMessage.value!,
                    actionLabel: 'Retry',
                    onAction: controller.retry,
                  ),
                )
              else if (controller.hasEmptyState)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AppMessageState(
                    icon: Icons.inventory_2_outlined,
                    message:
                        controller.infoMessage.value ?? 'No products found.',
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
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
