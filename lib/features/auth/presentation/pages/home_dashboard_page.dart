import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../../cart_orders/data/models/order_status.dart';
import '../../../dashboard/data/models/dashboard_order_preview_model.dart';
import '../../../dashboard/data/models/dashboard_range.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../dashboard/presentation/controllers/home_dashboard_controller.dart';
import '../controllers/home_controller.dart';

const _kNavy = Color(0xFF0D1B2A);
const _kGreen = Color(0xFF00C48C);

class HomeDashboardPage extends GetView<HomeDashboardController> {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final notificationController = Get.find<NotificationController>();
    final topPadding = MediaQuery.of(context).padding.top;

    return Obx(() {
      final hasDashboardData =
          controller.summary.value != null ||
          controller.nextDueOrders.isNotEmpty ||
          controller.recentOrders.isNotEmpty;

      if (controller.isInitialLoading.value && !hasDashboardData) {
        return const SafeArea(child: _DashboardLoadingState());
      }

      if (controller.errorMessage.value != null && !hasDashboardData) {
        return SafeArea(
          child: AppMessageState(
            icon: Icons.cloud_off_outlined,
            message: controller.errorMessage.value!,
            actionLabel: 'Retry',
            onAction: controller.retry,
          ),
        );
      }

      return Column(
        children: [
          _DashboardHeader(
            topPadding: topPadding,
            controller: controller,
            homeController: homeController,
            notificationController: notificationController,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: controller.showInlineLoader
                ? const LinearProgressIndicator(minHeight: 3)
                : const SizedBox.shrink(),
          ),
          if (controller.errorMessage.value != null && hasDashboardData)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _InlineErrorBanner(
                message: controller.errorMessage.value!,
                onRetry: controller.retry,
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _GlanceSection(controller: controller),
                  const SizedBox(height: 20),
                  _TodaysPlanSection(
                    controller: controller,
                    homeController: homeController,
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
    });
  }
}

// ─── Dark Header ──────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.topPadding,
    required this.controller,
    required this.homeController,
    required this.notificationController,
  });

  final double topPadding;
  final HomeDashboardController controller;
  final HomeController homeController;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 22),
          _buildSalesRow(),
          const SizedBox(height: 20),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  homeController.user.value?.name ?? 'Salesman',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        _SyncButton(homeController: homeController),
        _NotificationButton(
          homeController: homeController,
          notificationController: notificationController,
        ),
        const SizedBox(width: 4),
        Obx(
          () => CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1E3A5F),
            child: Text(
              (homeController.user.value?.name ?? 'S')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "TODAY'S SALES",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
            const Spacer(),
            _HeaderFilterChip(controller: controller),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.formatCurrency(controller.summary.value?.salesAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Confirmed orders only',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: homeController.openNewOrder,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New order'),
            style: FilledButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.receipt_long_outlined,
          tooltip: 'Orders',
          onTap: homeController.openOrdersTab,
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.groups_outlined,
          tooltip: 'Customers',
          onTap: () => homeController.changeTab(2),
        ),
      ],
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.homeController});
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final syncManager = homeController.syncManager;
      if (syncManager == null) return const SizedBox.shrink();

      final count = syncManager.pendingActionsCount.value;
      final isSyncing = syncManager.isSyncing.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Sync Offline Data',
            onPressed: isSyncing ? null : syncManager.triggerManualSync,
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.homeController,
    required this.notificationController,
  });
  final HomeController homeController;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: homeController.openNotifications,
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white,
            ),
          ),
          if (notificationController.unreadCount.value > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  notificationController.unreadCount.value > 99
                      ? '99+'
                      : notificationController.unreadCount.value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HeaderFilterChip extends StatelessWidget {
  const _HeaderFilterChip({required this.controller});
  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => _openRangeSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                controller.selectedRange.value.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRangeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<DashboardRange>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
      ),
    );

    if (selected == null) return;

    if (selected == DashboardRange.custom) {
      if (!context.mounted) return;
      final picked = await controller.pickCustomDateRange(context);
      if (picked == null) return;
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

// ─── Glance Grid ──────────────────────────────────────────────────────────────

class _GlanceSection extends StatelessWidget {
  const _GlanceSection({required this.controller});
  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today at a glance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _GlanceCard(
              label: 'Orders',
              value: '${summary?.totalOrdersCount ?? 0}',
              icon: Icons.receipt_long_outlined,
              iconBg: const Color(0xFFE8F0FE),
              iconColor: const Color(0xFF1A73E8),
              onTap: () => controller.openSummaryMetric('total_orders_count'),
            ),
            _GlanceCard(
              label: 'Drafts',
              value: '${summary?.draftOrdersCount ?? 0}',
              icon: Icons.edit_note_outlined,
              iconBg: const Color(0xFFFFF4D6),
              iconColor: const Color(0xFF92400E),
              onTap: () => controller.openSummaryMetric('draft_orders_count'),
            ),
            _GlanceCard(
              label: 'Confirmed',
              value: '${summary?.confirmedOrdersCount ?? 0}',
              icon: Icons.verified_outlined,
              iconBg: const Color(0xFFDFF7EA),
              iconColor: const Color(0xFF166534),
              onTap: () =>
                  controller.openSummaryMetric('confirmed_orders_count'),
            ),
            _GlanceCard(
              label: 'Overdue',
              value: '${summary?.overdueDeliveriesCount ?? 0}',
              icon: Icons.alarm_outlined,
              iconBg: const Color(0xFFFFE1E1),
              iconColor: const Color(0xFFB42318),
              accentBorder: true,
              onTap: () =>
                  controller.openSummaryMetric('overdue_deliveries_count'),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  const _GlanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.accentBorder = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: accentBorder
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFB42318), width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Today's Plan ─────────────────────────────────────────────────────────────

class _TodaysPlanSection extends StatelessWidget {
  const _TodaysPlanSection({
    required this.controller,
    required this.homeController,
  });

  final HomeDashboardController controller;
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    final orders = controller.nextDueOrders;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's plan",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${orders.length} upcoming deliveries',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: homeController.openOrdersTab,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Route'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (orders.isEmpty)
              Text(
                'No upcoming due orders.',
                style: theme.textTheme.bodyMedium,
              )
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

// ─── Recent Orders Section ────────────────────────────────────────────────────

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
                _StatusPill(
                  status: order.status,
                  label: order.status?.label ?? '-',
                ),
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

// ─── Error Banner ─────────────────────────────────────────────────────────────

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

// ─── Loading State ────────────────────────────────────────────────────────────

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
