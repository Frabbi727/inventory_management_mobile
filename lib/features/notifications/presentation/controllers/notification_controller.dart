import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/notification_item_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  NotificationController({
    required NotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  final NotificationRepository _notificationRepository;

  final notifications = <NotificationItemModel>[].obs;
  final unreadCount = 0.obs;
  final selectedStatus = RxnString();
  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final isMarkingAllRead = false.obs;
  final openingNotificationId = RxnInt();
  final errorMessage = RxnString();

  bool _hasLoadedOnce = false;
  int _currentPage = 1;
  int _lastPage = 1;

  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasMore => _currentPage < _lastPage;

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshUnreadCount());
  }

  Future<void> ensureLoaded() async {
    if (_hasLoadedOnce) {
      return;
    }

    await fetchNotifications(reset: true);
  }

  Future<void> refreshIfLoaded() async {
    if (!_hasLoadedOnce) {
      return;
    }

    await fetchNotifications(reset: true);
  }

  Future<void> changeStatus(String? status) async {
    if (selectedStatus.value == status) {
      return;
    }

    selectedStatus.value = status;
    await fetchNotifications(reset: true);
  }

  Future<void> refreshUnreadCount() async {
    try {
      final response = await _notificationRepository.fetchUnreadCount();
      unreadCount.value = response.count ?? 0;
    } catch (_) {
      // Badge refresh is best-effort.
    }
  }

  Future<void> fetchNotifications({required bool reset}) async {
    if (reset) {
      isInitialLoading.value = notifications.isEmpty;
      isRefreshing.value = notifications.isNotEmpty;
      errorMessage.value = null;
      _currentPage = 1;
    } else {
      if (isLoadingMore.value || !hasMore) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final response = await _notificationRepository.fetchNotifications(
        page: _currentPage,
        status: selectedStatus.value,
      );

      final fetchedItems = response.data ?? const <NotificationItemModel>[];
      _lastPage = response.meta?.lastPage ?? 1;

      if (reset) {
        notifications.assignAll(fetchedItems);
      } else {
        notifications.addAll(fetchedItems);
      }

      _hasLoadedOnce = true;
      if (_currentPage < _lastPage) {
        _currentPage++;
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (reset) {
        notifications.clear();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load notifications right now.';
      if (reset) {
        notifications.clear();
      }
    } finally {
      isInitialLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() => fetchNotifications(reset: false);

  Future<void> markAsRead(NotificationItemModel item) async {
    final notificationId = item.id;
    if (notificationId == null || item.isRead == true) {
      return;
    }

    final index = notifications.indexWhere(
      (entry) => entry.id == notificationId,
    );
    if (index == -1) {
      return;
    }

    final previous = notifications[index];
    notifications[index] = previous.copyWith(
      isRead: true,
      readAt: DateTime.now().toUtc().toIso8601String(),
    );
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }

    try {
      await _notificationRepository.markAsRead(notificationId);
      await refreshUnreadCount();
    } catch (_) {
      notifications[index] = previous;
      await refreshUnreadCount();
    }
  }

  Future<void> markAsUnread(NotificationItemModel item) async {
    final notificationId = item.id;
    if (notificationId == null || item.isRead == false) {
      return;
    }

    final index = notifications.indexWhere(
      (entry) => entry.id == notificationId,
    );
    if (index == -1) {
      return;
    }

    final previous = notifications[index];
    notifications[index] = previous.copyWith(isRead: false, readAt: null);
    unreadCount.value++;

    try {
      await _notificationRepository.markAsUnread(notificationId);
      await refreshUnreadCount();
    } catch (_) {
      notifications[index] = previous;
      await refreshUnreadCount();
    }
  }

  Future<void> markAsReadById(int notificationId) async {
    final index = notifications.indexWhere(
      (entry) => entry.id == notificationId,
    );
    if (index != -1) {
      await markAsRead(notifications[index]);
      return;
    }

    try {
      await _notificationRepository.markAsRead(notificationId);
    } catch (_) {
      // Read sync from push tap is best-effort.
    } finally {
      await refreshUnreadCount();
      await refreshIfLoaded();
    }
  }

  Future<void> markAllAsRead() async {
    if (notifications.isEmpty) {
      return;
    }

    isMarkingAllRead.value = true;
    final previousItems = notifications.toList();
    final now = DateTime.now().toUtc().toIso8601String();
    notifications.assignAll(
      notifications
          .map(
            (item) => item.copyWith(isRead: true, readAt: item.readAt ?? now),
          )
          .toList(),
    );
    unreadCount.value = 0;

    try {
      await _notificationRepository.markAllAsRead();
      await refreshUnreadCount();
    } catch (_) {
      notifications.assignAll(previousItems);
      await refreshUnreadCount();
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  Future<void> openNotification(NotificationItemModel item) async {
    final notificationId = item.id;
    if (openingNotificationId.value != null) {
      return;
    }

    openingNotificationId.value = notificationId ?? -1;

    try {
      if (item.isRead != true) {
        await markAsRead(item);
      }

      final entity = item.entity;
      if (entity?.type == 'order' && entity?.id != null) {
        await Get.toNamed(AppRoutes.orderDetails, arguments: entity!.id);
      }
    } finally {
      openingNotificationId.value = null;
    }
  }
}
