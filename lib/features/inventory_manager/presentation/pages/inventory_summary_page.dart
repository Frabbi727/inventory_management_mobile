import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';

class InventorySummaryPage extends StatefulWidget {
  const InventorySummaryPage({super.key});

  @override
  State<InventorySummaryPage> createState() => _InventorySummaryPageState();
}

class _InventorySummaryPageState extends State<InventorySummaryPage> {
  late final ProductListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProductListController>();
    _controller.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Obx(() {
        final products = _controller.products.toList();
        final lowStockProducts = products
            .where(_isLowStock)
            .toList(growable: false);
        final outOfStockProducts = products
            .where((product) => (product.currentStock ?? 0) <= 0)
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () => _controller.ensureLoaded(forceRefresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppPageHeader(
                title: 'Inventory',
                subtitle:
                    'Watch stock health, low-stock exposure, and the products that need attention.',
                trailing: OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.inventoryLowStock),
                  child: const Text('Low Stock'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Products',
                      value: '${products.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Low stock',
                      value: '${lowStockProducts.length}',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Out of stock',
                      value: '${outOfStockProducts.length}',
                      icon: Icons.remove_shopping_cart_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Categories',
                      value:
                          '${products.map((e) => e.category?.id).whereType<int>().toSet().length}',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Needs Attention',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (lowStockProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No low-stock products right now.'),
                  ),
                )
              else
                ...lowStockProducts
                    .take(8)
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttentionCard(product: product),
                      ),
                    ),
            ],
          ),
        );
      }),
    );
  }

  bool _isLowStock(ProductModel product) {
    final currentStock = product.currentStock ?? 0;
    final minimumStockAlert = product.minimumStockAlert ?? 0;
    return currentStock <= minimumStockAlert;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(product.name ?? 'Unnamed product'),
        subtitle: Text(
          'Stock ${product.currentStock ?? 0} | Alert ${product.minimumStockAlert ?? 0}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(AppRoutes.productDetails, arguments: product),
      ),
    );
  }
}
