import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../controllers/purchase_records_controller.dart';
import '../../data/models/inventory_purchase_model.dart';

class PurchaseRecordsPage extends GetView<PurchaseRecordsController> {
  const PurchaseRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        actions: [
          IconButton(
            tooltip: 'Create purchase',
            onPressed: controller.openCreatePurchase,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreatePurchase,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              _PurchaseToolbar(controller: controller),
              const SizedBox(height: 12),
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: controller.activeFilterCount == 0
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (controller.hasActiveSearch)
                                _FilterChip(
                                  label: 'Search: ${controller.searchQuery.value}',
                                ),
                              if (controller.hasActiveDateFilter)
                                _FilterChip(label: controller.dateRangeLabel),
                              ActionChip(
                                label: const Text('Reset'),
                                avatar: const Icon(
                                  Icons.restart_alt,
                                  size: 18,
                                ),
                                onPressed: controller.clearAllCriteria,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isInitialLoading.value &&
                      controller.purchases.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.errorMessage.value != null &&
                      controller.purchases.isEmpty) {
                    return AppMessageState(
                      icon: Icons.cloud_off_outlined,
                      message: controller.errorMessage.value!,
                      actionLabel: 'Retry',
                      onAction: controller.retry,
                    );
                  }

                  return Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child:
                            controller.errorMessage.value != null &&
                                controller.purchases.isNotEmpty
                            ? _InlineBanner(
                                message: controller.errorMessage.value!,
                                onRetry: controller.retry,
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: controller.showInlineLoader
                            ? const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            : const SizedBox(height: 0),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: controller.retry,
                          edgeOffset: 12,
                          displacement: 28,
                          child: controller.purchases.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.5,
                                      child: AppMessageState(
                                        icon: controller.hasAnyQueryApplied
                                            ? Icons.search_off_outlined
                                            : Icons.inventory_2_outlined,
                                        message:
                                            controller.infoMessage.value ??
                                            'No purchases available.',
                                        actionLabel:
                                            controller.hasAnyQueryApplied
                                            ? 'Clear filters'
                                            : 'Refresh',
                                        onAction:
                                            controller.hasAnyQueryApplied
                                            ? controller.clearAllCriteria
                                            : controller.retry,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  controller: controller.scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 112,
                                  ),
                                  itemCount:
                                      controller.purchases.length +
                                      (controller.isLoadingMore.value ? 1 : 0),
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index >= controller.purchases.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final purchase = controller.purchases[index];
                                    return _PurchaseCard(
                                      purchase: purchase,
                                      formatDate: controller.formatDate,
                                      formatCurrency:
                                          controller.formatCurrency,
                                      onOpen: () => controller
                                          .openPurchaseEditor(purchase),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseToolbar extends StatelessWidget {
  const _PurchaseToolbar({required this.controller});

  final PurchaseRecordsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: controller.searchTextController,
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search purchase no or note',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.isSearching.value
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : controller.searchTextController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: controller.clearSearch,
                          icon: const Icon(Icons.close),
                        ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.pickDateRange(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.dateRangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: 'Clear filters',
                    onPressed: controller.hasAnyQueryApplied
                        ? controller.clearAllCriteria
                        : null,
                    icon: const Icon(Icons.restart_alt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${controller.purchases.length} loaded',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.hasAnyQueryApplied
                          ? 'Search and date filters work together across pages.'
                          : 'Pull down to refresh the latest purchases.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.formatDate,
    required this.formatCurrency,
    required this.onOpen,
  });

  final InventoryPurchaseModel purchase;
  final String Function(String? value) formatDate;
  final String Function(num? value) formatCurrency;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = purchase.note?.trim();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                          purchase.purchaseNo?.isNotEmpty == true
                              ? purchase.purchaseNo!
                              : 'Purchase #${purchase.id ?? '-'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatDate(purchase.purchaseDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Open'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    label: 'Total',
                    value: formatCurrency(purchase.totalAmount),
                  ),
                  _InfoPill(
                    label: 'Items',
                    value: '${purchase.itemsCount ?? 0}',
                  ),
                  _InfoPill(
                    label: 'Creator',
                    value: purchase.creator?.name ?? '-',
                  ),
                ],
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    note,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
