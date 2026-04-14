import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/create_purchase_controller.dart';
import '../models/purchase_draft_item.dart';
import '../widgets/inventory_catalog_widgets.dart';
import '../widgets/inventory_cetaogry_filter.dart';

class CreatePurchasePage extends GetView<CreatePurchaseController> {
  const CreatePurchasePage({super.key});

  Future<void> _openFiltersSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Obx(
        () => InventoryProductFilterSheet(
          categories: controller.categories.toList(growable: false),
          subcategories: controller.subcategories.toList(growable: false),
          initialCategoryId: controller.selectedCategoryId.value,
          initialSubcategoryId: controller.selectedSubcategoryId.value,
          initialStockStatus: controller.selectedStockStatus.value,
          isCategoriesLoading: controller.isCategoriesLoading.value,
          isSubcategoriesLoading: controller.isSubcategoriesLoading.value,
          onLoadSubcategories: controller.loadSubcategories,
          onApply: (categoryId, subcategoryId, stockStatus) {
            return controller.applyFilters(
              categoryId: categoryId,
              subcategoryId: subcategoryId,
              stockStatus: stockStatus,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Purchase')),
      body: SafeArea(
        child: Obx(() {
          final draftQuantity = controller.draftItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
          final activeFilterCount =
              (controller.hasActiveCategory ? 1 : 0) +
              (controller.hasActiveSubcategory ? 1 : 0) +
              (controller.hasActiveStockStatus ? 1 : 0);

          return ListView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            children: [
              _PurchaseHero(
                controller: controller,
                draftQuantity: draftQuantity,
              ),
              const SizedBox(height: 16),
              _PurchaseDraftWorkspace(
                controller: controller,
                draftQuantity: draftQuantity,
              ),
              const SizedBox(height: 18),
              _CatalogWorkspaceHeader(
                hasActiveFilter: controller.hasActiveFilter,
                activeFilterCount: activeFilterCount,
                onOpenFilters: () => _openFiltersSheet(context),
                onResetFilters: controller.clearFilters,
              ),
              const SizedBox(height: 12),
              _CatalogSearchBar(controller: controller),
              const SizedBox(height: 16),
              Text(
                'Tap a product to prepare a purchase line. Barcode scans can resolve a simple product or a specific variant.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (controller.isInitialLoading.value &&
                  controller.products.isEmpty)
                const _CenteredLoadingState()
              else if (controller.hasErrorState)
                _CatalogErrorState(
                  message:
                      controller.errorMessage.value ??
                      'Unable to load products.',
                  onRetry: controller.retry,
                )
              else if (controller.hasEmptyState)
                _CatalogEmptyState(message: controller.emptyStateMessage)
              else
                ...controller.visibleProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InventoryProductCard(
                      product: product,
                      onTap: () => controller.openPurchaseDetails(product),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Obx(
          () => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${controller.draftItems.length} draft lines',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.formatCurrency(controller.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submitPurchase,
                    icon: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Save Purchase'),
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

class _PurchaseHero extends StatelessWidget {
  const _PurchaseHero({required this.controller, required this.draftQuantity});

  final CreatePurchaseController controller;
  final int draftQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Draft-based receiving',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Build the final purchase payload first. The backend will validate duplicate lines, variant rules, totals, and stock-safe update behavior.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.tonalIcon(
                onPressed: controller.isResolvingBarcode.value
                    ? null
                    : controller.openScanner,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                icon: controller.isResolvingBarcode.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(
                label: 'Draft Lines',
                value: '${controller.draftItems.length}',
              ),
              _HeroStat(label: 'Qty Total', value: '$draftQuantity'),
              _HeroStat(
                label: 'Draft Total',
                value: controller.formatCurrency(controller.totalAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseDraftWorkspace extends StatelessWidget {
  const _PurchaseDraftWorkspace({
    required this.controller,
    required this.draftQuantity,
  });

  final CreatePurchaseController controller;
  final int draftQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase Draft',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Date, note, and lines live here. Tap any draft line to revise quantity, unit cost, or variant selection.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DraftInfoCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Purchase Date',
                  value: controller.formatDate(controller.purchaseDate.value),
                  onTap: () => controller.pickDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniSummaryCard(
                  label: 'Draft Qty',
                  value: '$draftQuantity',
                  tone: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Internal note',
              alignLabelWithHint: true,
              hintText:
                  'Supplier note, warehouse context, or receiving comment',
              border: OutlineInputBorder(),
            ),
          ),
          if (controller.submitError.value != null) ...[
            const SizedBox(height: 12),
            _InlineErrorText(message: controller.submitError.value!),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Draft Lines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (controller.draftItems.isNotEmpty)
                Text(
                  'Tap to edit',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.draftItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No draft lines yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose products from the catalog below or scan a barcode. Variant products will ask for a variant before they can be saved.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...controller.draftItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DraftItemCard(
                  item: item,
                  formatCurrency: controller.formatCurrency,
                  onTap: item.product == null
                      ? null
                      : () => controller.openDraftItemEditor(item),
                  onRemove: () => controller.removeDraftItem(item.lineKey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogWorkspaceHeader extends StatelessWidget {
  const _CatalogWorkspaceHeader({
    required this.hasActiveFilter,
    required this.activeFilterCount,
    required this.onOpenFilters,
    required this.onResetFilters,
  });

  final bool hasActiveFilter;
  final int activeFilterCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Products',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveFilter
                      ? '$activeFilterCount active filters applied'
                      : 'Search the product catalog or filter by category and stock status.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              hasActiveFilter ? 'Filters ($activeFilterCount)' : 'Filters',
            ),
          ),
          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: onResetFilters,
              tooltip: 'Reset filters',
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogSearchBar extends StatelessWidget {
  const _CatalogSearchBar({required this.controller});

  final CreatePurchaseController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchTextController,
      onChanged: controller.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by product name, SKU, barcode, or variant label',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.hasActiveSearch
            ? IconButton(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _DraftItemCard extends StatelessWidget {
  const _DraftItemCard({
    required this.item,
    required this.formatCurrency,
    required this.onRemove,
    this.onTap,
  });

  final PurchaseDraftItem item;
  final String Function(num value) formatCurrency;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.38,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.barcode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove draft line',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if ((item.variantLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _TagRow(
                tags: [
                  'Variant: ${item.variantLabel}',
                  ...?item.optionValues?.entries.map(
                    (entry) => '${entry.key}: ${entry.value}',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CompactPill(label: 'Qty', value: '${item.quantity}'),
                _CompactPill(
                  label: 'Unit Cost',
                  value: formatCurrency(item.unitCost),
                ),
                _CompactPill(
                  label: 'Line Total',
                  value: formatCurrency(item.totalAmount),
                ),
                _CompactPill(label: 'Stock', value: '${item.currentStock}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftInfoCard extends StatelessWidget {
  const _DraftInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  const _CompactPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.62,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}

class _CenteredLoadingState extends StatelessWidget {
  const _CenteredLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
