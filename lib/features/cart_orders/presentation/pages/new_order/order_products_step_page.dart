import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../../../../shared/widgets/app_message_state.dart';
import '../../../../../shared/widgets/app_searchable_select.dart';
import '../../controllers/order_products_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';

class OrderProductsStepPage extends GetView<OrderProductsStepController> {
  const OrderProductsStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final productController = controller.productListController;
      final cartController = controller.cartController;
      final _ = cartController.items.length;

      controller.syncSearchField();

      final products = controller.products;
      final categories = productController.categories;
      final selectedCategoryId = productController.selectedCategoryId.value;
      final selectedSubcategoryId =
          productController.selectedSubcategoryId.value;
      final showInitialLoader =
          productController.isInitialLoading.value && products.isEmpty;
      final showErrorState = productController.hasErrorState;
      final showEmptyState = productController.hasEmptyState;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OrderSearchField(
                        controller: controller.searchController,
                        hintText: 'Search by product name or SKU',
                        isLoading: productController.isSearching.value,
                        onChanged: controller.onSearchChanged,
                        onClear: controller.clearSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => controller.scanBarcode(context),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      tooltip: 'Scan barcode',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productController.hasActiveSearch
                            ? 'Search results'
                            : productController.hasActiveCategory ||
                                  productController.hasActiveSubcategory
                            ? 'Filtered products'
                            : 'Available products',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _openFilterSheet(context),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune),
                          if (productController.hasActiveCategory ||
                              productController.hasActiveSubcategory)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${(selectedCategoryId != null ? 1 : 0) + (selectedSubcategoryId != null ? 1 : 0)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('Filters'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (products.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${products.length} FOUND',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (productController.hasActiveCategory) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categories
                                  .firstWhereOrNull(
                                    (category) =>
                                        category.id == selectedCategoryId,
                                  )
                                  ?.name ??
                              'Category selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (productController.hasActiveFilter)
                      TextButton.icon(
                        onPressed: controller.clearFilters,
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 18,
                        ),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                if (productController.errorMessage.value != null &&
                    products.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InlineWarningBanner(
                    message: productController.errorMessage.value!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: productController.retry,
              child: CustomScrollView(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (showInitialLoader)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (showErrorState)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppMessageState(
                        icon: Icons.cloud_off_outlined,
                        message: productController.errorMessage.value!,
                        actionLabel: 'Retry',
                        onAction: productController.retry,
                      ),
                    )
                  else if (showEmptyState)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppMessageState(
                        icon: Icons.inventory_2_outlined,
                        message:
                            productController.infoMessage.value ??
                            'No products matched your search.',
                        actionLabel: productController.hasActiveFilter
                            ? 'Clear Filters'
                            : 'Refresh',
                        onAction: productController.hasActiveFilter
                            ? () async => controller.clearFilters()
                            : () async => productController.retry(),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final selectedQuantity = cartController
                            .quantityForProduct(product.id);
                        final unitLabel =
                            product.unit?.shortName ?? product.unit?.name;
                        final displayPrice = product.hasVariants == true
                            ? product.lowestVariantSellingPrice
                            : product.sellingPrice;

                        return ProductCard(
                          key: ValueKey('product-card-${product.id}'),
                          name: product.name ?? 'Unnamed product',
                          sku: product.sku ?? '-',
                          price: product.hasVariants == true
                              ? 'From ${productController.formatPrice(displayPrice)}'
                              : productController.formatPrice(displayPrice),
                          stock: product.currentStock ?? 0,
                          selectedQuantity: selectedQuantity,
                          imageUrl: product.primaryPhotoUrl,
                          unitLabel: unitLabel == null
                              ? null
                              : 'Unit $unitLabel',
                          categoryLabel: product.category?.name,
                          buttonLabel: 'Add',
                          showQuantityControls: product.hasVariants != true,
                          onViewDetails: () {
                            Get.toNamed(
                              AppRoutes.productDetails,
                              arguments: product,
                            );
                          },
                          onAdd: () =>
                              controller.openQuickAddSheet(context, product),
                          onIncrement: product.hasVariants == true
                              ? null
                              : () => cartController.incrementQuantity(
                                  '${product.id}:base',
                                ),
                          onDecrement: product.hasVariants == true
                              ? null
                              : () => cartController.decrementQuantity(
                                  '${product.id}:base',
                                ),
                          onQuantitySubmitted: product.hasVariants == true
                              ? null
                              : (value) => controller.updateProductQuantity(
                                  product,
                                  value,
                                ),
                        );
                      },
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: productController.isLoadingMore.value
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final productController = controller.productListController;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Obx(() {
              final categoryOptions = controller.categoryOptions();
              final subcategoryOptions = controller.subcategoryOptions();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Products',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a category and subcategory to narrow the item list.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppSearchableSelectField<int>(
                    label: 'Category',
                    searchHint: 'Search category',
                    options: categoryOptions,
                    value: productController.selectedCategoryId.value,
                    placeholder: productController.categories.isEmpty
                        ? 'No categories available'
                        : 'All categories',
                    prefixIcon: Icons.category_outlined,
                    onChanged: productController.onCategoryChanged,
                    enabled: productController.categories.isNotEmpty,
                    isLoading: productController.isCategoriesLoading.value,
                    helperText: 'Filter products by category.',
                    clearLabel: 'All categories',
                  ),
                  const SizedBox(height: 12),
                  AppSearchableSelectField<int>(
                    label: 'Subcategory',
                    searchHint: 'Search subcategory',
                    options: subcategoryOptions,
                    value: productController.selectedSubcategoryId.value,
                    placeholder:
                        productController.selectedCategoryId.value == null
                        ? 'Select a category first'
                        : productController.subcategories.isEmpty
                        ? 'No subcategories available'
                        : 'All subcategories',
                    prefixIcon: Icons.account_tree_outlined,
                    onChanged:
                        productController.selectedCategoryId.value == null
                        ? null
                        : productController.onSubcategoryChanged,
                    enabled: productController.selectedCategoryId.value != null,
                    isLoading: productController.isSubcategoriesLoading.value,
                    helperText:
                        productController.selectedCategoryId.value == null
                        ? 'Choose a category to load subcategories.'
                        : 'Refine the selected category.',
                    clearLabel:
                        productController.selectedCategoryId.value == null
                        ? null
                        : 'All subcategories',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.clearFilters();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
