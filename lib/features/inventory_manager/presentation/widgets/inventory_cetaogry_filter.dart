import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_searchable_select.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../../../products/data/models/product_subcategory_model.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading && categories.isEmpty) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          child: LinearProgressIndicator(),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _InventoryCategoryChip(
              label: 'All',
              isSelected: selectedCategoryId == null,
              onTap: onReset,
            ),
            const SizedBox(width: 10),
            ...categories.expand(
              (category) => [
                _InventoryCategoryChip(
                  label: category.name ?? 'Category',
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => onSelectCategory(category.id),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (hasActiveCategory)
                TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InventoryCategoryChip(
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: onReset,
              ),
              ...categories.map(
                (category) => _InventoryCategoryChip(
                  label: category.name ?? 'Category',
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => onSelectCategory(category.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InventoryProductFilterPanel extends StatelessWidget {
  const InventoryProductFilterPanel({
    super.key,
    required this.categories,
    required this.subcategories,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.selectedStockStatus,
    required this.isCategoriesLoading,
    required this.isSubcategoriesLoading,
    required this.hasActiveFilter,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onStockStatusChanged,
    required this.onReset,
  });

  final List<CategoryModel> categories;
  final List<ProductSubcategoryModel> subcategories;
  final int? selectedCategoryId;
  final int? selectedSubcategoryId;
  final ProductStockStatus? selectedStockStatus;
  final bool isCategoriesLoading;
  final bool isSubcategoriesLoading;
  final bool hasActiveFilter;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onSubcategoryChanged;
  final ValueChanged<ProductStockStatus?> onStockStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
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
                      'Filters',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Narrow products by category, subcategory, and stock state.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilter)
                TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 14),
          AppSearchableSelectField<int>(
            label: 'Category',
            searchHint: 'Search category',
            placeholder: 'All categories',
            prefixIcon: Icons.category_outlined,
            options: categories
                .map(
                  (category) => AppSearchableSelectOption<int>(
                    value: category.id ?? -1,
                    label: category.name ?? 'Category',
                    searchTerms: ['${category.id ?? ''}'],
                  ),
                )
                .where((option) => option.value != -1)
                .toList(growable: false),
            value: selectedCategoryId,
            onChanged: onCategoryChanged,
            isLoading: isCategoriesLoading,
            clearLabel: 'All categories',
          ),
          const SizedBox(height: 12),
          AppSearchableSelectField<int>(
            label: 'Subcategory',
            searchHint: 'Search subcategory',
            placeholder: selectedCategoryId == null
                ? 'Select category first'
                : 'All subcategories',
            prefixIcon: Icons.account_tree_outlined,
            options: subcategories
                .map(
                  (subcategory) => AppSearchableSelectOption<int>(
                    value: subcategory.id ?? -1,
                    label: subcategory.name ?? 'Subcategory',
                    searchTerms: ['${subcategory.id ?? ''}'],
                  ),
                )
                .where((option) => option.value != -1)
                .toList(growable: false),
            value: selectedSubcategoryId,
            onChanged: selectedCategoryId == null ? null : onSubcategoryChanged,
            enabled: selectedCategoryId != null,
            isLoading: isSubcategoriesLoading,
            clearLabel: selectedCategoryId == null ? null : 'All subcategories',
            helperText: selectedCategoryId == null
                ? 'Choose a category to load subcategories.'
                : subcategories.isEmpty && !isSubcategoriesLoading
                ? 'No subcategories available for the selected category.'
                : null,
          ),
          const SizedBox(height: 12),
          AppSearchableSelectField<ProductStockStatus>(
            label: 'Stock Status',
            searchHint: 'Search stock status',
            placeholder: 'All stock statuses',
            prefixIcon: Icons.inventory_2_outlined,
            options: ProductStockStatus.values
                .map(
                  (status) => AppSearchableSelectOption<ProductStockStatus>(
                    value: status,
                    label: status.displayLabel,
                    subtitle: switch (status) {
                      ProductStockStatus.inStock =>
                        'Products available above the minimum alert level',
                      ProductStockStatus.lowStock =>
                        'Products at or below the minimum alert level',
                      ProductStockStatus.outOfStock =>
                        'Products with zero or unavailable stock',
                    },
                    searchTerms: [status.apiValue],
                  ),
                )
                .toList(growable: false),
            value: selectedStockStatus,
            onChanged: onStockStatusChanged,
            clearLabel: 'All stock statuses',
          ),
        ],
      ),
    );
  }
}

class _InventoryCategoryChip extends StatelessWidget {
  const _InventoryCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
