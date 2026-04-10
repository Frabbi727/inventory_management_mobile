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
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _ModernCategoryChip(
              label: 'All',
              icon: Icons.apps_rounded,
              isSelected: selectedCategoryId == null,
              onTap: onReset,
            ),
            const SizedBox(width: 10),
            ...categories.expand(
                  (category) => [
                _ModernCategoryChip(
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
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a category to narrow product results.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveCategory)
                TextButton.icon(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ModernCategoryChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    isSelected: selectedCategoryId == null,
                    onTap: onReset,
                  );
                }

                final category = categories[index - 1];
                final isSelected = category.id == selectedCategoryId;

                return _ModernCategoryChip(
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

class _ModernCategoryChip extends StatelessWidget {
  const _ModernCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected
              ? null
              : colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}