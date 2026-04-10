import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/product_stock_status_badge.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../controllers/inventory_summary_controller.dart';

class InventorySummaryPage extends StatefulWidget {
  const InventorySummaryPage({super.key});

  @override
  State<InventorySummaryPage> createState() => _InventorySummaryPageState();
}

class _InventorySummaryPageState extends State<InventorySummaryPage> {
  final InventorySummaryController controller = Get.find();
  InventoryStatusFilter selectedFilter = InventoryStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Obx(() {
        final allProducts = controller.products.toList(growable: false);
        final inStockProducts = _filterByStatus(
          allProducts,
          ProductStockStatus.inStock,
        );
        final lowStockProducts = _filterByStatus(
          allProducts,
          ProductStockStatus.lowStock,
        );
        final outOfStockProducts = _filterByStatus(
          allProducts,
          ProductStockStatus.outOfStock,
        );
        final needsAttentionProducts = [
          ...outOfStockProducts,
          ...lowStockProducts,
        ];
        final filteredProducts = switch (selectedFilter) {
          InventoryStatusFilter.all => allProducts,
          InventoryStatusFilter.inStock => inStockProducts,
          InventoryStatusFilter.low => lowStockProducts,
          InventoryStatusFilter.out => outOfStockProducts,
        };

        return RefreshIndicator(
          onRefresh: controller.retry,
          child: ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AppPageHeader(
                title: 'Inventory',
                subtitle:
                    'Watch stock health, low-stock exposure, and the products that need attention.',
                trailing: OutlinedButton.icon(
                  onPressed: controller.openLowStock,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Low Stock'),
                ),
              ),
              const SizedBox(height: 20),
              _InventoryOverviewBanner(
                attentionCount: needsAttentionProducts.length,
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _SummaryCard(
                    label: 'Total',
                    value: '${allProducts.length}',
                    icon: Icons.inventory_2_outlined,
                    accentColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF3FBFA),
                  ),
                  _SummaryCard(
                    label: 'In Stock',
                    value: '${inStockProducts.length}',
                    icon: ProductStockStatus.inStock.icon,
                    accentColor: ProductStockStatus.inStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.inStock.surfaceTintColor,
                  ),
                  _SummaryCard(
                    label: 'Low Stock',
                    value: '${lowStockProducts.length}',
                    icon: ProductStockStatus.lowStock.icon,
                    accentColor: ProductStockStatus.lowStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.lowStock.surfaceTintColor,
                  ),
                  _SummaryCard(
                    label: 'Out of Stock',
                    value: '${outOfStockProducts.length}',
                    icon: ProductStockStatus.outOfStock.icon,
                    accentColor: ProductStockStatus.outOfStock.accentColor,
                    backgroundColor:
                        ProductStockStatus.outOfStock.surfaceTintColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Status',
                subtitle: 'Filter the product list by stock health.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: InventoryStatusFilter.values
                    .map((filter) {
                      final isSelected = selectedFilter == filter;
                      final status = filter.status;
                      final accentColor =
                          status?.accentColor ?? colorScheme.primary;
                      final backgroundColor = isSelected
                          ? accentColor.withValues(alpha: 0.12)
                          : Colors.white;

                      return FilterChip(
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                        label: Text(filter.label),
                        avatar: Icon(
                          filter.icon,
                          size: 18,
                          color: isSelected
                              ? accentColor
                              : colorScheme.onSurfaceVariant,
                        ),
                        backgroundColor: backgroundColor,
                        selectedColor: backgroundColor,
                        side: BorderSide(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.28)
                              : colorScheme.outlineVariant,
                        ),
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? accentColor
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 24),
              _NeedsAttentionSection(
                products: needsAttentionProducts,
                onProductTap: controller.openDetails,
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

  List<ProductModel> _filterByStatus(
    List<ProductModel> products,
    ProductStockStatus status,
  ) {
    return products
        .where((product) => _statusOf(product) == status)
        .toList(growable: false);
  }

  ProductStockStatus _statusOf(ProductModel product) {
    return product.effectiveStockStatus;
  }
}

enum InventoryStatusFilter {
  all('All', Icons.grid_view_rounded),
  inStock('In Stock', Icons.check_circle_rounded, ProductStockStatus.inStock),
  low('Low', Icons.warning_amber_rounded, ProductStockStatus.lowStock),
  out('Out', Icons.cancel_rounded, ProductStockStatus.outOfStock);

  const InventoryStatusFilter(this.label, this.icon, [this.status]);

  final String label;
  final IconData icon;
  final ProductStockStatus? status;

  String get sectionTitle => switch (this) {
    InventoryStatusFilter.all => 'All Products',
    InventoryStatusFilter.inStock => 'In-Stock Products',
    InventoryStatusFilter.low => 'Low-Stock Products',
    InventoryStatusFilter.out => 'Out-of-Stock Products',
  };
}

class _InventoryOverviewBanner extends StatelessWidget {
  const _InventoryOverviewBanner({required this.attentionCount});

  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF129990)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F766E),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory at a glance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attentionCount == 0
                      ? 'Everything looks healthy right now.'
                      : '$attentionCount product(s) need attention today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection({
    required this.products,
    required this.onProductTap,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onProductTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF8D89A)),
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
                  color: const Color(0xFFFFF4DB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF9A6700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Needs Attention',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      products.isEmpty
                          ? 'No low-stock or out-of-stock products right now.'
                          : 'Prioritize these products before they impact sales.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...products
                .take(4)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InventoryProductTile(
                      product: product,
                      onTap: () => onProductTap(product),
                      emphasizeStatus: true,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _InventoryProductTile extends StatelessWidget {
  const _InventoryProductTile({
    required this.product,
    required this.onTap,
    this.emphasizeStatus = false,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final bool emphasizeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = product.effectiveStockStatus;
    final accentColor = status.accentColor;
    final backgroundColor =
        emphasizeStatus || status != ProductStockStatus.inStock
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
