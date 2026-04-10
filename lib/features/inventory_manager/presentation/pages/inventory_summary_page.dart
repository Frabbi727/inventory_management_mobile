import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/product_stock_status_badge.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../controllers/inventory_summary_controller.dart';

class InventorySummaryPage extends GetView<InventorySummaryController> {
  const InventorySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final selectedFilter = controller.selectedFilter.value;
        final filteredProducts = controller.filteredProducts;

        return RefreshIndicator(
          onRefresh: controller.retry,
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AppPageHeader(
                title: 'Inventory'),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _SummaryCard(
                    isSelected: selectedFilter == InventoryStatusFilter.all,
                    onTap: () =>
                        controller.selectFilter(InventoryStatusFilter.all),
                    label: 'Total',
                    value: '${controller.allProducts.length}',
                    icon: Icons.inventory_2_outlined,
                    accentColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF3FBFA),
                  ),
                  _SummaryCard(
                    isSelected: selectedFilter == InventoryStatusFilter.inStock,
                    onTap: () =>
                        controller.selectFilter(InventoryStatusFilter.inStock),
                    label: 'In Stock',
                    value: '${controller.inStockProducts.length}',
                    icon: ProductStockStatus.inStock.icon,
                    accentColor: ProductStockStatus.inStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.inStock.surfaceTintColor,
                  ),
                  _SummaryCard(
                    isSelected: selectedFilter == InventoryStatusFilter.low,
                    onTap: () =>
                        controller.selectFilter(InventoryStatusFilter.low),
                    label: 'Low Stock',
                    value: '${controller.lowStockProducts.length}',
                    icon: ProductStockStatus.lowStock.icon,
                    accentColor: ProductStockStatus.lowStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.lowStock.surfaceTintColor,
                  ),
                  _SummaryCard(
                    isSelected: selectedFilter == InventoryStatusFilter.out,
                    onTap: () =>
                        controller.selectFilter(InventoryStatusFilter.out),
                    label: 'Out of Stock',
                    value: '${controller.outOfStockProducts.length}',
                    icon: ProductStockStatus.outOfStock.icon,
                    accentColor: ProductStockStatus.outOfStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.outOfStock.surfaceTintColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: selectedFilter.sectionTitle,
                subtitle: '${filteredProducts.length} product(s)',
              ),
              const SizedBox(height: 12),
              if (filteredProducts.isEmpty)
                _EmptyInventoryState(filter: selectedFilter)
              else
                ...filteredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InventoryProductTile(
                      product: product,
                      onTap: () => controller.openDetails(product),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}



class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBackground = isSelected ? backgroundColor : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.45)
                  : const Color(0xFFE6EAF0),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.18)
                    : const Color(0x120F172A),
                blurRadius: isSelected ? 28 : 24,
                offset: Offset(0, isSelected ? 14 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 18,
                    color: isSelected
                        ? accentColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InventoryProductTile extends StatelessWidget {
  const _InventoryProductTile({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = product.effectiveStockStatus;
    final accentColor = status.accentColor;
    final backgroundColor = status != ProductStockStatus.inStock
        ? status.surfaceTintColor
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: status == ProductStockStatus.inStock
                  ? const Color(0xFFE6EAF0)
                  : status.borderColor,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unnamed product',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Stock ${product.currentStock ?? 0}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Min ${product.minimumStockAlert ?? 0}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ProductStockStatusBadge(
                            status: status,
                            showIcon: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.filter});

  final InventoryStatusFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(filter.icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No products match the ${filter.label.toLowerCase()} filter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
