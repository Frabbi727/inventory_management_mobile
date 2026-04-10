import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../controllers/purchase_flow_controller.dart';
import '../models/barcode_scan_models.dart';
import 'product_form_page.dart';

class CreatePurchasePage extends StatefulWidget {
  const CreatePurchasePage({super.key});

  @override
  State<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends State<CreatePurchasePage> {
  late final ProductListController _productListController;
  late final PurchaseFlowController _purchaseFlowController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productListController = Get.find<ProductListController>();
    _purchaseFlowController = Get.find<PurchaseFlowController>();
    _productListController.ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: SafeArea(
        child: Obx(() {
          final products = _productListController.products.toList(
            growable: false,
          );

          return RefreshIndicator(
            onRefresh: () =>
                _productListController.ensureLoaded(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Search products, filter by category, or scan a barcode to start receiving for one product at a time.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _productListController.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by product name, SKU, or barcode',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _productListController.hasActiveSearch
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _productListController.clearSearch();
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed:
                          _purchaseFlowController.isResolvingBarcode.value
                          ? null
                          : _openScanner,
                      icon: _purchaseFlowController.isResolvingBarcode.value
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
                _PurchaseCategoryFilterSection(
                  controller: _productListController,
                ),
                const SizedBox(height: 20),
                Text(
                  'Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_productListController.isInitialLoading.value &&
                    products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_productListController.hasErrorState)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productListController.errorMessage.value ??
                                'Unable to load products.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _productListController.retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (products.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No products found for the current search and category filters.',
                      ),
                    ),
                  )
                else
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PurchaseProductCard(
                        product: product,
                        onTap: () => _openPurchaseDetails(product),
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

  Future<void> _openScanner() async {
    final result = await Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.purchaseLookup,
      ),
    );

    if (result is! BarcodeScanResult) {
      return;
    }

    try {
      final product = await _purchaseFlowController.getPurchaseProductByBarcode(
        result.barcode,
      );
      if (product?.id == null) {
        _showProductNotFoundDialog(result.barcode);
        return;
      }

      _openPurchaseDetails(product!);
    } catch (_) {
      Get.snackbar(
        'Unable to resolve barcode',
        'The barcode could not be matched right now. Please try again.',
      );
    }
  }

  void _openPurchaseDetails(ProductModel product) {
    Get.toNamed(AppRoutes.inventoryPurchaseDetails, arguments: product);
  }

  void _showProductNotFoundDialog(String barcode) {
    Get.dialog(
      AlertDialog(
        title: const Text('Product not found'),
        content: Text(
          'No existing product matched "$barcode". You can create a new product or return to the list.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Back')),
          FilledButton(
            onPressed: () {
              Get.back();
              Get.toNamed(
                AppRoutes.inventoryProductForm,
                arguments: ProductFormArgs.create(barcode: barcode),
              );
            },
            child: const Text('Create Product'),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCategoryFilterSection extends StatelessWidget {
  const _PurchaseCategoryFilterSection({required this.controller});

  final ProductListController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.categories.toList(growable: false);
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: controller.selectedCategoryId.value == null,
            onSelected: (_) => controller.clearCategory(),
          ),
          const SizedBox(width: 8),
          ...categories.expand(
            (category) => <Widget>[
              FilterChip(
                label: Text(category.name ?? 'Category'),
                selected: controller.selectedCategoryId.value == category.id,
                onSelected: (_) => controller.onCategoryChanged(category.id),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseProductCard extends StatelessWidget {
  const _PurchaseProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unnamed product',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('SKU: ${product.sku ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Barcode: ${product.barcode ?? '-'}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          label: 'Stock',
                          value: '${product.currentStock ?? 0}',
                        ),
                        _MetaPill(
                          label: 'Category',
                          value: product.category?.name ?? '-',
                        ),
                        _MetaPill(
                          label: 'Cost',
                          value: '৳${(product.purchasePrice ?? 0).toString()}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
