import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/presentation/controllers/home_controller.dart';
import '../../../cart_orders/presentation/controllers/cart_controller.dart';
import '../../data/models/product_model.dart';
import '../controllers/product_list_controller.dart';

class ProductListPage extends GetView<ProductListController> {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartController = Get.find<CartController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SearchBar(
              controller: controller.searchController,
              hintText: 'Search by product name or SKU',
              leading: const Icon(Icons.search),
              onChanged: controller.onSearchChanged,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.infoMessage.value == null ||
                  controller.searchQuery.value.isNotEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.infoMessage.value!,
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
            Expanded(
              child: Obx(() {
                if (controller.isInitialLoading.value &&
                    controller.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value != null &&
                    controller.products.isEmpty) {
                  return _ErrorState(
                    message: controller.errorMessage.value!,
                    onRetry: controller.retry,
                  );
                }

                if (controller.products.isEmpty) {
                  return _EmptyState(
                    message:
                        controller.infoMessage.value ??
                        'No products available.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.retry,
                  child: ListView.separated(
                    controller: controller.scrollController,
                    itemCount:
                        controller.products.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= controller.products.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final product = controller.products[index];
                      final lowStock = (product.currentStock ?? 0) <= 5;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name ?? 'Unnamed product',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.sku ?? '-',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: (product.currentStock ?? 0) <= 0
                                        ? null
                                        : () => _addToOrder(
                                            context,
                                            cartController,
                                            product,
                                          ),
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add'),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(
                                    icon: Icons.sell_outlined,
                                    label: 'Price',
                                    value: controller.formatPrice(
                                      product.sellingPrice,
                                    ),
                                  ),
                                  _StockChip(
                                    stock: product.currentStock ?? 0,
                                    lowStock: lowStock,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _addToOrder(
    BuildContext context,
    CartController cartController,
    ProductModel product,
  ) {
    final added = cartController.addProduct(product);
    final messenger = ScaffoldMessenger.of(context);

    if (!added) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            (product.currentStock ?? 0) <= 0
                ? '${product.name ?? 'Product'} is out of stock.'
                : 'Available stock limit reached for ${product.name ?? 'this product'}.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.name ?? 'Product'} added to the order'),
        action: Get.isRegistered<HomeController>()
            ? SnackBarAction(
                label: cartController.canOpenProductsStepFromProductsTab()
                    ? 'Review Order'
                    : 'View',
                onPressed: () {
                  cartController.openProductsStepFromProductsTab();
                  Get.find<HomeController>().changeTab(1);
                },
              )
            : null,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label: $value', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.stock, required this.lowStock});

  final int stock;
  final bool lowStock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = lowStock
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = lowStock
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            'Stock: $stock',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
