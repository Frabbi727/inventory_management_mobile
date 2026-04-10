import 'package:flutter/material.dart';

import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_model.dart';

class InventoryQuickActionCard extends StatelessWidget {
  const InventoryQuickActionCard({
    super.key,
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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

class InventoryCategoryFilterSection extends StatelessWidget {
  const InventoryCategoryFilterSection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.isLoading,
    required this.hasActiveCategory,
    required this.onReset,
    required this.onSelectCategory,
    this.compact = false,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final bool isLoading;
  final bool hasActiveCategory;
  final VoidCallback onReset;
  final ValueChanged<int?> onSelectCategory;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isLoading && categories.isEmpty) {
      return const SizedBox(height: 48, child: LinearProgressIndicator());
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: selectedCategoryId == null,
              onSelected: (_) => onReset(),
            ),
            const SizedBox(width: 8),
            ...categories.expand(
              (category) => <Widget>[
                FilterChip(
                  label: Text(category.name ?? 'Category'),
                  selected: selectedCategoryId == category.id,
                  onSelected: (_) => onSelectCategory(category.id),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Filter',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse one product group at a time.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (hasActiveCategory)
                TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategoryId;
                return _CategoryPill(
                  label: category.name ?? 'Category ${category.id ?? index}',
                  isSelected: isSelected,
                  onTap: () => onSelectCategory(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryProductCard extends StatelessWidget {
  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

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
                        InventoryMetaPill(
                          label: 'Stock',
                          value: '${product.currentStock ?? 0}',
                        ),
                        InventoryMetaPill(
                          label: 'Category',
                          value: product.category?.name ?? '-',
                        ),
                        InventoryMetaPill(
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

class InventoryMetaPill extends StatelessWidget {
  const InventoryMetaPill({
    super.key,
    required this.label,
    required this.value,
  });

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

class InventoryInfoChip extends StatelessWidget {
  const InventoryInfoChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
