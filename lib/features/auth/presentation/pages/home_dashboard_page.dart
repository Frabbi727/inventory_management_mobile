import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/data/models/order_status.dart';
import '../../../dashboard/data/models/dashboard_order_preview_model.dart';
import '../../../dashboard/data/models/dashboard_range.dart';
import '../../../dashboard/presentation/controllers/home_dashboard_controller.dart';
import '../controllers/home_controller.dart';

class HomeDashboardPage extends GetView<HomeDashboardController> {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return SafeArea(
      child: Obx(() {
        final hasDashboardData =
            controller.summary.value != null ||
            controller.nextDueOrders.isNotEmpty ||
            controller.recentOrders.isNotEmpty;

        if (controller.isInitialLoading.value && !hasDashboardData) {
          return const _DashboardLoadingState();
        }

        if (controller.errorMessage.value != null && !hasDashboardData) {
          return AppMessageState(
            icon: Icons.cloud_off_outlined,
            message: controller.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: controller.retry,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppPageHeader(
                    title: 'Home',
                    subtitle:
                        'Track today first, then jump straight into action.',
                    trailing: CircleAvatar(
                      child: Text(
                        (homeController.user.value?.name ?? 'S')[0]
                            .toUpperCase(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: controller.showInlineLoader
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(minHeight: 3),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (controller.errorMessage.value != null && hasDashboardData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InlineErrorBanner(
                        message: controller.errorMessage.value!,
                        onRetry: controller.retry,
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                      'Summary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Order date based',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _SummaryFilterButton(controller: controller),
                            ],
                          ),
                          if (controller.appliedFilters.value?.startDate !=
                                  null &&
                              controller.appliedFilters.value?.endDate !=
                                  null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range_outlined,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${controller.formatDate(controller.appliedFilters.value?.startDate)} - ${controller.formatDate(controller.appliedFilters.value?.endDate)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                edgeOffset: 12,
                displacement: 28,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    _SummaryGrid(controller: controller),
                    const SizedBox(height: 16),
                    _OrderPreviewSection(
                      title: 'Next Due Orders',
                      subtitle: 'Upcoming draft deliveries for this salesman.',
                      orders: controller.nextDueOrders,
                      emptyMessage: 'No upcoming due orders.',
                      controller: controller,
                    ),
                    const SizedBox(height: 16),
                    _OrderPreviewSection(
                      title: 'Recent Orders',
                      subtitle: 'Latest order updates for this salesman.',
                      orders: controller.recentOrders,
                      emptyMessage: 'No recent orders found.',
                      controller: controller,
                    ),
                    if (controller.infoMessage.value != null &&
                        !hasDashboardData &&
                        controller.errorMessage.value == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: AppMessageState(
                          icon: Icons.dashboard_customize_outlined,
                          message: controller.infoMessage.value!,
                          actionLabel: 'Refresh',
                          onAction: controller.refresh,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryFilterButton extends StatelessWidget {
  const _SummaryFilterButton({required this.controller});

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () => _openRangeSheet(context),
      icon: const Icon(Icons.tune),
      label: Text(controller.selectedRange.value.label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Future<void> _openRangeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<DashboardRange>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Summary range',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              for (final range in DashboardRange.values)
                ListTile(
                  leading: Icon(
                    controller.selectedRange.value == range
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(range.label),
                  onTap: () => Navigator.of(context).pop(range),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (selected == DashboardRange.custom) {
      if (!context.mounted) {
        return;
      }
      final picked = await controller.pickCustomDateRange(context);
      if (picked == null) {
        return;
      }
      await controller.applyRange(
        selected,
        startDate: picked.start,
        endDate: picked.end,
      );
      return;
    }

    await controller.applyRange(selected);
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller});

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary.value;

    final items = [
      _SummaryItem(
        title: 'Sales Amount (Confirm Order Only)',
        value: controller.formatCurrency(summary?.salesAmount),
        icon: Icons.payments_outlined,
        onTap: () => controller.openSummaryMetric('sales_amount'),
      ),
      _SummaryItem(
        title: 'Total Orders',
        value: '${summary?.totalOrdersCount ?? 0}',
        icon: Icons.receipt_long_outlined,
        onTap: () => controller.openSummaryMetric('total_orders_count'),
      ),
      _SummaryItem(
        title: 'Draft Orders',
        value: '${summary?.draftOrdersCount ?? 0}',
        icon: Icons.edit_note_outlined,
        accent: const _SummaryAccent(
          background: Color(0xFFFFF4D6),
          foreground: Color(0xFF92400E),
        ),
        onTap: () => controller.openSummaryMetric('draft_orders_count'),
      ),
      _SummaryItem(
        title: 'Confirmed',
        value: '${summary?.confirmedOrdersCount ?? 0}',
        icon: Icons.verified_outlined,
        accent: const _SummaryAccent(
          background: Color(0xFFDFF7EA),
          foreground: Color(0xFF166534),
        ),
        onTap: () => controller.openSummaryMetric('confirmed_orders_count'),
      ),
      _SummaryItem(
        title: 'Overdue',
        value: '${summary?.overdueDeliveriesCount ?? 0}',
        icon: Icons.alarm_outlined,
        onTap: () => controller.openSummaryMetric('overdue_deliveries_count'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 420 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 420 ? 2.0 : 1.9,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SummaryCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              accent: item.accent,
              onTap: item.onTap,
            );
          },
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    this.accent,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final _SummaryAccent? accent;
  final VoidCallback onTap;
}

class _SummaryAccent {
  const _SummaryAccent({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accent,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final _SummaryAccent? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent =
        accent ??
        _SummaryAccent(
          background: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.primary,
        );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: effectiveAccent.background,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 16,
                      color: effectiveAccent.foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: effectiveAccent.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPreviewSection extends StatelessWidget {
  const _OrderPreviewSection({
    required this.title,
    required this.subtitle,
    required this.orders,
    required this.emptyMessage,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final List<DashboardOrderPreviewModel> orders;
  final String emptyMessage;
  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            if (orders.isEmpty)
              Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderPreviewTile(
                    order: order,
                    controller: controller,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderPreviewTile extends StatelessWidget {
  const _OrderPreviewTile({required this.order, required this.controller});

  final DashboardOrderPreviewModel order;
  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => controller.openOrderDetails(order),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNo ?? 'Order',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customer?.name ?? '-',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.intendedDeliveryAt == null
                        ? controller.formatDate(order.orderDate)
                        : controller.formatDateTime(order.intendedDeliveryAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatCurrency(order.grandTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusPill(status: order.status, label: order.status?.label ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.status});

  final String label;
  final OrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _statusTone(theme.colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tone.foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _StatusTone _statusTone(ColorScheme colorScheme) {
    switch (status) {
      case OrderStatus.confirmed:
        return const _StatusTone(
          backgroundColor: Color(0xFFDFF7EA),
          foregroundColor: Color(0xFF166534),
        );
      case OrderStatus.draft:
        return const _StatusTone(
          backgroundColor: Color(0xFFFFF4D6),
          foregroundColor: Color(0xFF92400E),
        );
      case OrderStatus.cancelled:
        return const _StatusTone(
          backgroundColor: Color(0xFFFFE1E1),
          foregroundColor: Color(0xFFB42318),
        );
      case null:
        return _StatusTone(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusTone {
  const _StatusTone({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onError),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: List.generate(
        5,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(child: Container(height: 96)),
        ),
      ),
    );
  }
}
