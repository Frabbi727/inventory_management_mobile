import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../models/barcode_scan_models.dart';

class InventoryProductsPage extends StatefulWidget {
  const InventoryProductsPage({super.key});

  @override
  State<InventoryProductsPage> createState() => _InventoryProductsPageState();
}

class _InventoryProductsPageState extends State<InventoryProductsPage> {
  late final ProductListController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProductListController>();
    _controller.ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Obx(() {
        final products = _controller.products.toList();
        final recentProducts = products.take(5).toList();

        return RefreshIndicator(
          onRefresh: () => _controller.ensureLoaded(forceRefresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _controller.loadMoreIfNeeded(notification.metrics);
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                AppPageHeader(
                  title: 'Products',
                  subtitle:
                      'Scan first, then review product details or update stock-facing information.',
                  trailing: FilledButton.icon(
                    onPressed: _openScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Scan Barcode',
                        subtitle: 'Find an item or start a new product.',
                        onTap: _openScan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Low Stock',
                        subtitle:
                            'Review products below the minimum threshold.',
                        onTap: () => Get.toNamed(AppRoutes.inventoryLowStock),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name, SKU, or barcode',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.hasActiveSearch
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _controller.clearSearch();
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (recentProducts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Recent Products',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 124,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => _RecentProductCard(
                        product: recentProducts[index],
                        onTap: () => _openDetails(recentProducts[index]),
                      ),
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemCount: recentProducts.length,
                    ),
                  ),
                ],
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
                    if (_controller.hasActiveFilter)
                      TextButton(
                        onPressed: _controller.clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_controller.isInitialLoading.value && products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.hasErrorState)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppMessageState(
                      icon: Icons.cloud_off_outlined,
                      message: _controller.errorMessage.value!,
                      actionLabel: 'Retry',
                      onAction: _controller.retry,
                    ),
                  )
                else if (_controller.hasEmptyState)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppMessageState(
                      icon: Icons.inventory_2_outlined,
                      message:
                          _controller.infoMessage.value ?? 'No products found.',
                    ),
                  )
                else
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProductListCard(
                        product: product,
                        onTap: () => _openDetails(product),
                      ),
                    ),
                  ),
                if (_controller.isLoadingMore.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _openScan() {
    Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.productLookup,
      ),
    );
  }

  void _openDetails(ProductModel product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name ?? 'Unnamed product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'SKU: ${product.sku ?? '-'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product.currentStock ?? 0}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock =
        (product.currentStock ?? 0) <= (product.minimumStockAlert ?? 0);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name ?? 'Unnamed product',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${product.sku ?? '-'}'),
              const SizedBox(height: 4),
              Text('Barcode: ${product.barcode ?? '-'}'),
              const SizedBox(height: 4),
              Text(
                'Category: ${product.category?.name ?? '-'} | Unit: ${product.unit?.shortName ?? product.unit?.name ?? '-'}',
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.currentStock ?? 0}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLowStock ? 'Low stock' : 'In stock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLowStock
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
