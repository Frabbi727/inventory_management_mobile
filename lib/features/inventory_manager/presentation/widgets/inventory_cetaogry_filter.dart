import 'package:flutter/material.dart';

import '../../../products/data/models/category_response_model.dart';

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
