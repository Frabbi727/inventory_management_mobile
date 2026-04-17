import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_searchable_select.dart';
import '../../../inventory_manager/presentation/models/barcode_scan_models.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import 'cart_controller.dart';
import '../widgets/order_flow_widgets.dart';

class OrderProductsStepController extends GetxController {
  OrderProductsStepController({
    required CartController cartController,
    required ProductListController productListController,
    required ProductRepository productRepository,
  }) : _cartController = cartController,
       _productListController = productListController,
       _productRepository = productRepository;

  final CartController _cartController;
  final ProductListController _productListController;
  final ProductRepository _productRepository;

  late final TextEditingController searchController;
  late final ScrollController scrollController;

  CartController get cartController => _cartController;
  ProductListController get productListController => _productListController;
  List<ProductModel> get products => _productListController.products;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController(
      text: _productListController.searchQuery.value,
    );
    scrollController = ScrollController()..addListener(_handleScroll);
    _productListController.ensureLoaded();
  }

  Future<void> ensureLoaded() => _productListController.ensureLoaded();

  void onSearchChanged(String value) {
    _productListController.onSearchChanged(value);
  }

  void clearSearch() {
    searchController.clear();
    _productListController.clearSearch();
  }

  void clearFilters() {
    searchController.clear();
    _productListController.clearFilters();
  }

  void syncSearchField() {
    final value = _productListController.searchQuery.value;
    if (searchController.text == value) {
      return;
    }

    searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void updateProductQuantity(
    ProductModel product,
    int quantity, {
    ProductVariantModel? variant,
  }) {
    final existingQuantity = _cartController.quantityForLine(
      product.id,
      productVariantId: variant?.id,
    );

    if (existingQuantity > 0) {
      _cartController.setLineQuantity(
        _cartController.lineKeyFor(product.id, productVariantId: variant?.id),
        quantity,
      );
      return;
    }

    if (quantity <= 0) {
      return;
    }

    _cartController.addProduct(product, variant: variant, quantity: quantity);
  }

  Future<void> openQuickAddSheet(BuildContext context, ProductModel product) {
    if (product.hasVariants == true) {
      return _openVariantPicker(context, product);
    }

    return _openSimpleProductPicker(context, product);
  }

  Future<void> scanBarcode(BuildContext context) async {
    final result = await Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.salesOrderLookup,
      ),
    );

    if (result is! BarcodeScanResult) {
      return;
    }

    final scannedProduct = result.product;
    if (scannedProduct == null) {
      _cartController.errorMessage.value =
          'No product was found for this barcode.';
      return;
    }

    if (!context.mounted) {
      return;
    }

    await openQuickAddSheet(context, scannedProduct);
  }

  List<AppSearchableSelectOption<int>> categoryOptions() {
    return _productListController.categories
        .where((category) => category.id != null)
        .map(
          (category) => AppSearchableSelectOption<int>(
            value: category.id!,
            label: category.name ?? 'Category',
          ),
        )
        .toList(growable: false);
  }

  List<AppSearchableSelectOption<int>> subcategoryOptions() {
    return _productListController.subcategories
        .where((subcategory) => subcategory.id != null)
        .map(
          (subcategory) => AppSearchableSelectOption<int>(
            value: subcategory.id!,
            label: subcategory.name ?? 'Subcategory',
            searchTerms: [
              subcategory.name ?? '',
              _productListController.categories
                      .firstWhereOrNull(
                        (category) => category.id == subcategory.categoryId,
                      )
                      ?.name ??
                  '',
            ],
          ),
        )
        .toList(growable: false);
  }

  void _handleScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    _productListController.loadMoreIfNeeded(scrollController.position);
  }

  Future<ProductModel> _resolveVariantProduct(ProductModel product) async {
    if ((product.variants ?? const <ProductVariantModel>[]).isNotEmpty) {
      return product;
    }

    final response = await _productRepository.fetchProductDetails(product.id!);
    return response.data ?? product;
  }

  Future<void> _openSimpleProductPicker(
    BuildContext context,
    ProductModel product,
  ) async {
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
              final _ = _cartController.items.length;
              final quantity = _cartController.quantityForLine(product.id);
              final availableStock = product.currentStock ?? 0;
              final isUnavailable = availableStock <= 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'Quick Add Product',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_productListController.formatPrice(product.sellingPrice)} • Stock $availableStock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Type the quantity you want to add.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        QuantityStepper(
                          key: ValueKey('simple-qty-${product.id}'),
                          quantity: quantity,
                          onIncrement: isUnavailable
                              ? null
                              : () => updateProductQuantity(
                                  product,
                                  quantity + 1,
                                ),
                          onDecrement: quantity <= 0
                              ? null
                              : () => updateProductQuantity(
                                  product,
                                  quantity - 1,
                                ),
                          onSubmitted: isUnavailable
                              ? null
                              : (value) =>
                                    updateProductQuantity(product, value),
                          canIncrement: !isUnavailable,
                          enabled: !isUnavailable,
                        ),
                      ],
                    ),
                  ),
                  if (isUnavailable) ...[
                    const SizedBox(height: 12),
                    Text(
                      'This product is out of stock.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            Get.toNamed(
                              AppRoutes.productDetails,
                              arguments: product,
                            );
                          },
                          child: const Text('View Details'),
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

  Future<void> _openVariantPicker(
    BuildContext context,
    ProductModel product,
  ) async {
    final resolvedProduct = await _resolveVariantProduct(product);
    final variants = resolvedProduct.variants ?? const <ProductVariantModel>[];

    if (!context.mounted) {
      return;
    }

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
            child: variants.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedProduct.name ?? 'Select Variant',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variant information is not available right now. Open the details page to review this product.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                Get.toNamed(
                                  AppRoutes.productDetails,
                                  arguments: resolvedProduct,
                                );
                              },
                              child: const Text('View Details'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Obx(() {
                    final _ = _cartController.items.length;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolvedProduct.name ?? 'Select Variant',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a variant and type the quantity you want to add.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: variants.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final variant = variants[index];
                              final availableStock = variant.currentStock ?? 0;
                              final isUnavailable = availableStock <= 0;
                              final quantity = _cartController.quantityForLine(
                                resolvedProduct.id,
                                productVariantId: variant.id,
                              );

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                variant.combinationLabel ??
                                                    variant.combinationKey ??
                                                    'Variant',
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_productListController.formatPrice(variant.sellingPrice)} • Stock $availableStock',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        QuantityStepper(
                                          key: ValueKey(
                                            'variant-qty-${resolvedProduct.id}-${variant.id}',
                                          ),
                                          quantity: quantity,
                                          onIncrement: isUnavailable
                                              ? null
                                              : () => updateProductQuantity(
                                                  resolvedProduct,
                                                  quantity + 1,
                                                  variant: variant,
                                                ),
                                          onDecrement: quantity <= 0
                                              ? null
                                              : () => updateProductQuantity(
                                                  resolvedProduct,
                                                  quantity - 1,
                                                  variant: variant,
                                                ),
                                          onSubmitted: isUnavailable
                                              ? null
                                              : (value) =>
                                                    updateProductQuantity(
                                                      resolvedProduct,
                                                      value,
                                                      variant: variant,
                                                    ),
                                          canIncrement: !isUnavailable,
                                          enabled: !isUnavailable,
                                        ),
                                      ],
                                    ),
                                    if (isUnavailable) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'This variant is out of stock.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  Get.toNamed(
                                    AppRoutes.productDetails,
                                    arguments: resolvedProduct,
                                  );
                                },
                                child: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
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

  @override
  void onClose() {
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    searchController.dispose();
    super.onClose();
  }
}
