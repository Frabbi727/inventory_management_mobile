import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../../../cart_orders/presentation/controllers/cart_controller.dart';
import '../controllers/invoice_controller.dart';

class InvoicePage extends GetView<InvoiceController> {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => AppPageHeader(
                title: 'Orders',
                subtitle: controller.hasAnyQueryApplied
                    ? 'Refresh keeps your current filters and search applied.'
                    : 'Track recent orders and open any order for full details.',
                trailing: FilledButton.tonalIcon(
                  onPressed: () => _openFilterSheet(context),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune),
                      if (controller.activeFilterCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${controller.activeFilterCount}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('Filters'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => _OrderStatusTabs(
                activeStatus: controller.activeStatusTab.value,
                onChanged: controller.changeStatusTab,
              ),
            ),
            const SizedBox(height: 12),
            _OrdersToolbar(controller: controller),
            const SizedBox(height: 12),
            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: controller.activeFilterCount == 0
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActiveFiltersRow(
                          controller: controller,
                          onClearAll: () async {
                            await controller.clearAllCriteria();
                          },
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final orders = controller.orders;

                if (controller.isInitialLoading.value &&
                    controller.orders.isEmpty) {
                  return const _OrderLoadingState();
                }

                if (controller.errorMessage.value != null &&
                    controller.orders.isEmpty) {
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
                              controller.orders.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _InlineErrorBanner(
                                message: controller.errorMessage.value!,
                                onRetry: controller.retry,
                              ),
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
                        child: orders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                    child: AppMessageState(
                                      icon: controller.hasEffectiveSearchQuery
                                          ? Icons.search_off_outlined
                                          : Icons.receipt_long_outlined,
                                      message:
                                          controller.infoMessage.value ??
                                          (controller.hasEffectiveSearchQuery
                                              ? 'No loaded orders matched your search.'
                                              : 'No orders have been created yet.'),
                                      actionLabel:
                                          controller.hasEffectiveSearchQuery ||
                                              controller.hasActiveFilters
                                          ? 'Clear filters'
                                          : 'Refresh',
                                      onAction:
                                          controller.hasEffectiveSearchQuery ||
                                              controller.hasActiveFilters
                                          ? () async {
                                              await controller
                                                  .clearAllCriteria();
                                            }
                                          : controller.retry,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: controller.scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 96,
                                ),
                                itemCount:
                                    orders.length +
                                    (controller.isLoadingMore.value ? 1 : 0),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= orders.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final order = orders[index];
                                  return _OrderCard(
                                    order: order,
                                    formatCurrency: controller.formatCurrency,
                                    formatDate: controller.formatDate,
                                    onTap: () => _openOrderDetails(order),
                                    onEditDraft: order.status == 'draft'
                                        ? () => _editDraft(order)
                                        : null,
                                    onDeleteDraft: order.status == 'draft'
                                        ? () => _deleteDraft(order)
                                        : null,
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
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    var orderDateRange = controller.selectedOrderDateRange;
    var plannedDeliveryRange = controller.selectedIntendedDeliveryDateRange;
    var selectedDeliveryState = controller.deliveryState.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final sheetBackground = Color.alphaBlend(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
          colorScheme.surface,
        );
        final surfaceCardColor = colorScheme.surface.withValues(alpha: 0.96);
        final sectionLabelColor = colorScheme.onSurface.withValues(alpha: 0.95);
        final sectionBorderColor = colorScheme.outlineVariant.withValues(
          alpha: 0.55,
        );
        final dateFieldFill = Color.alphaBlend(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          colorScheme.surface,
        );
        final dateFieldBorder = colorScheme.outline.withValues(alpha: 0.44);
        final resetForeground = colorScheme.onSurface.withValues(alpha: 0.88);
        final resetBackground = colorScheme.surface;
        final resetBorder = colorScheme.outline.withValues(alpha: 0.42);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    6,
                    20,
                    20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceCardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: sectionBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order date',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: sectionLabelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Filter orders by order date from the backend.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FilterDateRangeButton(
                                label: 'Order dates',
                                placeholder: 'Select order date range',
                                range: orderDateRange,
                                onPressed: () async {
                                  final pickedRange = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    initialDateRange: orderDateRange,
                                  );
                                  if (pickedRange != null) {
                                    setModalState(
                                      () => orderDateRange = pickedRange,
                                    );
                                  }
                                },
                                theme: theme,
                                colorScheme: colorScheme,
                                fillColor: dateFieldFill,
                                borderColor: dateFieldBorder,
                                formatDate: controller.formatDate,
                              ),
                              if (orderDateRange != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    textStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    setModalState(() => orderDateRange = null);
                                  },
                                  child: const Text('Clear order dates'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceCardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: sectionBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planned delivery date',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: sectionLabelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Filter orders by intended delivery date from the backend.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FilterDateRangeButton(
                                label: 'Planned delivery',
                                placeholder: 'Select planned delivery range',
                                range: plannedDeliveryRange,
                                onPressed: () async {
                                  final pickedRange = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    initialDateRange: plannedDeliveryRange,
                                  );
                                  if (pickedRange != null) {
                                    setModalState(
                                      () => plannedDeliveryRange = pickedRange,
                                    );
                                  }
                                },
                                theme: theme,
                                colorScheme: colorScheme,
                                fillColor: dateFieldFill,
                                borderColor: dateFieldBorder,
                                formatDate: controller.formatDate,
                              ),
                              if (plannedDeliveryRange != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    textStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    setModalState(
                                      () => plannedDeliveryRange = null,
                                    );
                                  },
                                  child: const Text(
                                    'Clear planned delivery dates',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceCardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: sectionBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery state',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: sectionLabelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use backend due-state results while keeping the current draft and confirmed tabs.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _DeliveryStateChip(
                                    label: 'Due today',
                                    selected:
                                        selectedDeliveryState == 'due_today',
                                    onTap: () => setModalState(
                                      () => selectedDeliveryState =
                                          selectedDeliveryState == 'due_today'
                                          ? null
                                          : 'due_today',
                                    ),
                                  ),
                                  _DeliveryStateChip(
                                    label: 'Due tomorrow',
                                    selected:
                                        selectedDeliveryState == 'due_tomorrow',
                                    onTap: () => setModalState(
                                      () => selectedDeliveryState =
                                          selectedDeliveryState ==
                                              'due_tomorrow'
                                          ? null
                                          : 'due_tomorrow',
                                    ),
                                  ),
                                  _DeliveryStateChip(
                                    label: 'Overdue',
                                    selected:
                                        selectedDeliveryState == 'overdue',
                                    onTap: () => setModalState(
                                      () => selectedDeliveryState =
                                          selectedDeliveryState == 'overdue'
                                          ? null
                                          : 'overdue',
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedDeliveryState != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    textStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    setModalState(
                                      () => selectedDeliveryState = null,
                                    );
                                  },
                                  child: const Text('Clear delivery state'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: resetBackground,
                                  foregroundColor: resetForeground,
                                  side: BorderSide(
                                    color: resetBorder,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: theme.textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: resetForeground,
                                      ),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await controller.clearFilters();
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  disabledBackgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.45),
                                  disabledForegroundColor: colorScheme.onPrimary
                                      .withValues(alpha: 0.82),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: theme.textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onPrimary,
                                      ),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await controller.applyFilters(
                                    orderDateRange: orderDateRange,
                                    intendedDeliveryDateRange:
                                        plannedDeliveryRange,
                                    deliveryState: selectedDeliveryState,
                                  );
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openOrderDetails(OrderModel order) {
    if (order.id == null) {
      return;
    }

    Get.toNamed(AppRoutes.orderDetails, arguments: order);
  }

  Future<void> _editDraft(OrderModel order) async {
    if (order.status != 'draft' || order.id == null) {
      return;
    }

    final cartController = Get.find<CartController>();
    await cartController.hydrateDraftFromOrder(order);
    if (cartController.errorMessage.value != null) {
      return;
    }

    await Get.toNamed(AppRoutes.newOrder);
  }

  Future<void> _deleteDraft(OrderModel order) async {
    if (order.status != 'draft' || order.id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: Get.context!,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Draft'),
        content: Text(
          'Delete ${order.orderNo ?? 'this draft order'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final cartController = Get.find<CartController>();
    final didDelete = await cartController.deleteDraft(orderId: order.id);
    if (!didDelete) {
      return;
    }

    await controller.retry();
  }
}

class _OrderStatusTabs extends StatelessWidget {
  const _OrderStatusTabs({required this.activeStatus, required this.onChanged});

  final String activeStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusTabChip(
              label: 'Draft',
              selected: activeStatus == 'draft',
              onTap: () => onChanged('draft'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatusTabChip(
              label: 'Confirm',
              selected: activeStatus == 'confirmed',
              onTap: () => onChanged('confirmed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabChip extends StatelessWidget {
  const _StatusTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _OrdersToolbar extends StatelessWidget {
  const _OrdersToolbar({required this.controller});

  final InvoiceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: controller.searchTextController,
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                    'Search by order no, customer name, or customer phone',
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
                      '${controller.orders.length} visible',
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
                          ? 'Refreshing keeps your current view intact.'
                          : 'Pull down to refresh the latest orders.',
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

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.controller, required this.onClearAll});

  final InvoiceController controller;
  final Future<void> Function() onClearAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (controller.startDate.value != null &&
            controller.endDate.value != null)
          _FilterChip(
            label:
                'Order: ${controller.formatDate(controller.startDate.value)} - ${controller.formatDate(controller.endDate.value)}',
          ),
        if (controller.intendedDeliveryStart.value != null &&
            controller.intendedDeliveryEnd.value != null)
          _FilterChip(
            label:
                'Planned: ${controller.formatDate(controller.intendedDeliveryStart.value)} - ${controller.formatDate(controller.intendedDeliveryEnd.value)}',
          ),
        if (controller.deliveryState.value != null)
          _FilterChip(
            label: controller.deliveryStateLabel(
              controller.deliveryState.value,
            ),
          ),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return ActionChip(
              backgroundColor: theme.colorScheme.errorContainer,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.28),
              ),
              avatar: Icon(
                Icons.restart_alt,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              label: Text(
                'Clear all',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                onClearAll();
              },
            );
          },
        ),
      ],
    );
  }
}

class _FilterDateRangeButton extends StatelessWidget {
  const _FilterDateRangeButton({
    required this.label,
    required this.placeholder,
    required this.range,
    required this.onPressed,
    required this.theme,
    required this.colorScheme,
    required this.fillColor,
    required this.borderColor,
    required this.formatDate,
  });

  final String label;
  final String placeholder;
  final DateTimeRange? range;
  final VoidCallback onPressed;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Color fillColor;
  final Color borderColor;
  final String Function(String? value) formatDate;

  @override
  Widget build(BuildContext context) {
    final value = range == null
        ? placeholder
        : '${formatDate(range!.start.toIso8601String())} - ${formatDate(range!.end.toIso8601String())}';

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: fillColor,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(Icons.date_range_outlined, color: colorScheme.primary),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

class _DeliveryStateChip extends StatelessWidget {
  const _DeliveryStateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.formatCurrency,
    required this.formatDate,
    required this.onTap,
    this.onEditDraft,
    this.onDeleteDraft,
  });

  final OrderModel order;
  final String Function(num? value) formatCurrency;
  final String Function(String? value) formatDate;
  final VoidCallback onTap;
  final VoidCallback? onEditDraft;
  final VoidCallback? onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _statusStyle(context, order.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNo ?? 'Order',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customer?.name ?? 'Unknown customer',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((order.customer?.phone ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            order.customer!.phone!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(order.grandTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDate(order.orderDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(
                          label: _titleCase(order.status ?? 'unknown'),
                          backgroundColor: statusStyle.backgroundColor,
                          foregroundColor: statusStyle.foregroundColor,
                        ),
                        _MetaBadge(
                          icon: Icons.inventory_2_outlined,
                          label: '${order.items?.length ?? 0} items',
                        ),
                        if (onEditDraft != null)
                          TextButton.icon(
                            onPressed: onEditDraft,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                        if (onDeleteDraft != null)
                          TextButton.icon(
                            onPressed: onDeleteDraft,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _OrderStatusStyle _statusStyle(BuildContext context, String? status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch ((status ?? '').toLowerCase()) {
      case 'confirmed':
        return _OrderStatusStyle(
          backgroundColor: const Color(0xFFDFF7EA),
          foregroundColor: const Color(0xFF166534),
        );
      case 'draft':
        return _OrderStatusStyle(
          backgroundColor: const Color(0xFFFFF4D6),
          foregroundColor: const Color(0xFF92400E),
        );
      case 'cancelled':
        return _OrderStatusStyle(
          backgroundColor: const Color(0xFFFFE1E1),
          foregroundColor: const Color(0xFFB42318),
        );
      default:
        return _OrderStatusStyle(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
        );
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLoadingState extends StatelessWidget {
  const _OrderLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _OrderSkeletonCard(),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A271A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _OrderSkeletonCard extends StatelessWidget {
  const _OrderSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _SkeletonBox(size: const Size(48, 48), color: baseColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(size: const Size(120, 14), color: baseColor),
                      const SizedBox(height: 8),
                      _SkeletonBox(size: const Size(170, 14), color: baseColor),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SkeletonBox(size: const Size(72, 18), color: baseColor),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SkeletonBox(size: const Size(86, 30), color: baseColor),
                const SizedBox(width: 8),
                _SkeletonBox(size: const Size(82, 30), color: baseColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.size, required this.color});

  final Size size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _OrderStatusStyle {
  const _OrderStatusStyle({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}
