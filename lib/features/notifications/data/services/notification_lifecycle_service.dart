import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/device_token_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/services/device_token_provider.dart';
import '../../presentation/controllers/notification_controller.dart';

class NotificationLifecycleService {
  NotificationLifecycleService({
    required DeviceTokenProvider deviceTokenProvider,
    required TokenStorage tokenStorage,
    required DeviceTokenStorage deviceTokenStorage,
    required AuthRepository authRepository,
  }) : _deviceTokenProvider = deviceTokenProvider,
       _tokenStorage = tokenStorage,
       _deviceTokenStorage = deviceTokenStorage,
       _authRepository = authRepository;

  final DeviceTokenProvider _deviceTokenProvider;
  final TokenStorage _tokenStorage;
  final DeviceTokenStorage _deviceTokenStorage;
  final AuthRepository _authRepository;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<dynamic>? _notificationOpenedSubscription;
  bool _isInitialized = false;

  void ensureInitialized() {
    if (_isInitialized) {
      return;
    }

    try {
      _isInitialized = true;
      _tokenRefreshSubscription = _deviceTokenProvider.onTokenRefresh.listen(
        (token) => unawaited(_handleTokenRefresh(token)),
      );
      _notificationOpenedSubscription = _deviceTokenProvider.onMessageOpenedApp
          .listen((message) => unawaited(_handleOpenedMessage(message.data)));
      unawaited(_consumeInitialMessage());
    } catch (_) {
      // Widget tests can boot without Firebase initialized.
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _notificationOpenedSubscription?.cancel();
  }

  Future<void> _consumeInitialMessage() async {
    final message = await _deviceTokenProvider.getInitialMessage();
    if (message == null) {
      return;
    }

    await _handleOpenedMessage(message.data);
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    if (newToken.isEmpty) {
      return;
    }

    final authToken = await _tokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final previousToken = await _deviceTokenStorage.getToken();
    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != newToken) {
      try {
        await _authRepository.unregisterSpecificDevice(authToken, previousToken);
      } catch (_) {
        // Token replacement should not block the new registration attempt.
      }
    }

    try {
      await _authRepository.registerSpecificDeviceForSession(authToken, newToken);
    } catch (_) {
      // Token refresh registration is best-effort.
    }
  }

  Future<void> _handleOpenedMessage(Map<String, dynamic> data) async {
    final notificationId = _parseInt(data['notification_id']);
    final entityType = data['entity_type'] as String?;
    final entityId = _parseInt(data['entity_id']);

    if (notificationId != null &&
        Get.isRegistered<NotificationController>()) {
      unawaited(Get.find<NotificationController>().markAsReadById(notificationId));
    }

    if (entityType == 'order' && entityId != null) {
      await Get.toNamed(AppRoutes.orderDetails, arguments: entityId);
    }

    if (Get.isRegistered<NotificationController>()) {
      final controller = Get.find<NotificationController>();
      unawaited(controller.refreshUnreadCount());
      unawaited(controller.refreshIfLoaded());
    }
  }

  int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @visibleForTesting
  Future<void> debugHandleOpenedMessage(Map<String, dynamic> data) {
    return _handleOpenedMessage(data);
  }
}
