import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../data/models/notification_item_model.dart';
import '../controllers/notification_controller.dart';

class NotificationsPage extends GetView<NotificationController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.ensureLoaded();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(
              () => TextButton(
                onPressed: controller.isMarkingAllRead.value
                    ? null
                    : controller.markAllAsRead,
                child: controller.isMarkingAllRead.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Read all'),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, colorScheme.surface, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final items = controller.notifications;
            final isLoading = controller.isInitialLoading.value;
            final error = controller.errorMessage.value;

            if (isLoading && items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && items.isEmpty) {
              return AppMessageState(
                icon: Icons.notifications_off_outlined,
                message: error,
                actionLabel: 'Retry',
                onAction: () => controller.fetchNotifications(reset: true),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _NotificationsHeader(
                    unreadCount: controller.unreadCount.value,
                    selectedStatus: controller.selectedStatus.value,
                    onSelectStatus: controller.changeStatus,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshUnreadCount();
                      await controller.fetchNotifications(reset: true);
                    },
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: const [
                              SizedBox(height: 120),
                              _EmptyNotificationsState(),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount:
                                items.length + (controller.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= items.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: OutlinedButton(
                                    onPressed: controller.isLoadingMore.value
                                        ? null
                                        : controller.loadMore,
                                    child: controller.isLoadingMore.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Load more'),
                                  ),
                                );
                              }

                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _NotificationCard(
                                  item: item,
                                  isOpening:
                                      controller.openingNotificationId.value ==
                                      (item.id ?? -1),
                                  onTap: () =>
                                      controller.openNotification(item),
                                  onMarkRead: item.isRead == true
                                      ? null
                                      : () => controller.markAsRead(item),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  static String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value;
    }

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} $hour:$minute';
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.selectedStatus,
    required this.onSelectStatus,
  });

  final int unreadCount;
  final String? selectedStatus;
  final ValueChanged<String?> onSelectStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedStatus == null,
                  onTap: () => onSelectStatus(null),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Unread',
                  isSelected: selectedStatus == 'unread',
                  onTap: () => onSelectStatus('unread'),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Read',
                  isSelected: selectedStatus == 'read',
                  onTap: () => onSelectStatus('read'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isOpening,
    required this.onTap,
    required this.onMarkRead,
  });

  final NotificationItemModel item;
  final bool isOpening;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = item.isRead != true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: isOpening ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isUnread
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isUnread ? 0.08 : 0.04,
                ),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnread
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: isUnread
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title ?? 'Notification',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatusPill(isUnread: isUnread),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.body ?? '-',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          NotificationsPage._formatDateTime(item.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isOpening ? null : onTap,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: isOpening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Open details'),
                      ),
                    ),
                    if (onMarkRead != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: isOpening ? null : onMarkRead,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(126, 52),
                        ),
                        child: const Text('Mark read'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isUnread});

  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUnread
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isUnread
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isUnread ? 'Unread' : 'Read',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isUnread
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.9),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return const AppMessageState(
      icon: Icons.notifications_none_outlined,
      message: 'No notifications found.',
    );
  }
}
