import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/data/models/order_status.dart';
import '../../../cart_orders/presentation/controllers/cart_controller.dart';
import '../../../dashboard/data/models/dashboard_order_preview_model.dart';
import '../../../dashboard/data/models/dashboard_range.dart';
import '../../../dashboard/presentation/controllers/home_dashboard_controller.dart';
import '../controllers/home_controller.dart';

class HomeDashboardPage extends GetView<HomeDashboardController> {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final cartController = Get.find<CartController>();

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

        return RefreshIndicator(
          onRefresh: controller.refresh,
          edgeOffset: 12,
          displacement: 28,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              AppPageHeader(
                title: 'Home',
                subtitle: 'Track today first, then jump straight into action.',
                trailing: CircleAvatar(
                  child: Text(
                    (homeController.user.value?.name ?? 'S')[0].toUpperCase(),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Summary',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            'Order date based',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final range in DashboardRange.values)
                            ChoiceChip(
                              label: Text(range.label),
                              selected: controller.selectedRange.value == range,
                              onSelected: (_) async {
                                if (range == DashboardRange.custom) {
                                  final picked = await controller
                                      .pickCustomDateRange(context);
                                  if (picked == null) {
                                    return;
                                  }
                                  await controller.applyRange(
                                    range,
                                    startDate: picked.start,
                                    endDate: picked.end,
                                  );
                                  return;
                                }
                                await controller.applyRange(range);
                              },
                            ),
                        ],
                      ),
                      if (controller.appliedFilters.value?.startDate != null &&
                          controller.appliedFilters.value?.endDate != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${controller.formatDate(controller.appliedFilters.value?.startDate)} - ${controller.formatDate(controller.appliedFilters.value?.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
        );
      }),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller});

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary.value;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Sales Amount',
          value: controller.formatCurrency(summary?.salesAmount),
          icon: Icons.payments_outlined,
          onTap: () => controller.openSummaryMetric('sales_amount'),
        ),
        _SummaryCard(
          title: 'Total Orders',
          value: '${summary?.totalOrdersCount ?? 0}',
          icon: Icons.receipt_long_outlined,
          onTap: () => controller.openSummaryMetric('total_orders_count'),
        ),
        _SummaryCard(
          title: 'Draft Orders',
          value: '${summary?.draftOrdersCount ?? 0}',
          icon: Icons.edit_note_outlined,
          onTap: () => controller.openSummaryMetric('draft_orders_count'),
        ),
        _SummaryCard(
          title: 'Confirmed',
          value: '${summary?.confirmedOrdersCount ?? 0}',
          icon: Icons.verified_outlined,
          onTap: () => controller.openSummaryMetric('confirmed_orders_count'),
        ),
        _SummaryCard(
          title: 'Overdue',
          value: '${summary?.overdueDeliveriesCount ?? 0}',
          icon: Icons.alarm_outlined,
          onTap: () => controller.openSummaryMetric('overdue_deliveries_count'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
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
                _StatusPill(label: order.status?.label ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
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
