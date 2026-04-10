import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_page_header.dart';
import '../controllers/inventory_summary_controller.dart';

class InventorySummaryPage extends GetView<InventorySummaryController> {
  const InventorySummaryPage({super.key});

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
                title: 'Inventory',
                subtitle:
                    'Watch stock health, low-stock exposure, and the products that need attention.',
                trailing: OutlinedButton(
                  onPressed: controller.openLowStock,
                  child: const Text('Low Stock'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Products',
                      value: '${controller.products.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Low stock',
                      value: '${controller.lowStockProducts.length}',
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
                      value: '${controller.outOfStockProducts.length}',
                      icon: Icons.remove_shopping_cart_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Categories',
                      value: '${controller.categoryCount}',
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
              if (controller.lowStockProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No low-stock products right now.'),
                  ),
                )
              else
                ...controller.lowStockProducts
                    .take(8)
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            title: Text(product.name ?? 'Unnamed product'),
                            subtitle: Text(
                              'Stock ${product.currentStock ?? 0} | Alert ${product.minimumStockAlert ?? 0}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => controller.openDetails(product),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
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
