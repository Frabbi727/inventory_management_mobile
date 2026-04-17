import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../controllers/notification_controller.dart';

class NotificationsPage extends GetView<NotificationController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.ensureLoaded();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(
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
        ],
      ),
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: controller.selectedStatus.value == null,
                      onTap: () => controller.changeStatus(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unread',
                      isSelected: controller.selectedStatus.value == 'unread',
                      onTap: () => controller.changeStatus('unread'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Read',
                      isSelected: controller.selectedStatus.value == 'read',
                      onTap: () => controller.changeStatus('read'),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Unread ${controller.unreadCount.value}'),
                    ),
                  ],
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
                          children: const [
                            SizedBox(height: 120),
                            _EmptyNotificationsState(),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length + (controller.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
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
                            return Card(
                              margin: const EdgeInsets.only(top: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => controller.openNotification(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title ?? 'Notification',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (item.isRead != true)
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item.body ?? '-'),
                                      const SizedBox(height: 12),
                                      Text(
                                        _formatDateTime(item.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed: item.isRead == true
                                                ? () => controller.markAsUnread(item)
                                                : () => controller.markAsRead(item),
                                            child: Text(
                                              item.isRead == true
                                                  ? 'Mark unread'
                                                  : 'Mark read',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () =>
                                                controller.openNotification(item),
                                            child: const Text('Open'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
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
