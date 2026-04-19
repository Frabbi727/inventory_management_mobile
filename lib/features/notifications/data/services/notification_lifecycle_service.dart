import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/device_token_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/services/device_token_provider.dart';
import '../models/notification_tap_payload_model.dart';
import 'notification_display_service.dart';
import '../../presentation/controllers/notification_controller.dart';

class NotificationLifecycleService {
  NotificationLifecycleService({
    required DeviceTokenProvider deviceTokenProvider,
    required NotificationDisplayService notificationDisplayService,
    required TokenStorage tokenStorage,
    required DeviceTokenStorage deviceTokenStorage,
    required AuthRepository authRepository,
  }) : _deviceTokenProvider = deviceTokenProvider,
       _notificationDisplayService = notificationDisplayService,
       _tokenStorage = tokenStorage,
       _deviceTokenStorage = deviceTokenStorage,
       _authRepository = authRepository;

  final DeviceTokenProvider _deviceTokenProvider;
  final NotificationDisplayService _notificationDisplayService;
  final TokenStorage _tokenStorage;
  final DeviceTokenStorage _deviceTokenStorage;
  final AuthRepository _authRepository;

  StreamSubscription<dynamic>? _foregroundMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<dynamic>? _notificationOpenedSubscription;
  StreamSubscription<NotificationTapPayloadModel>? _localTapSubscription;
  bool _isInitialized = false;

  Future<void> ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    try {
      _isInitialized = true;
      await _notificationDisplayService.initialize();
      _foregroundMessageSubscription = _deviceTokenProvider.onMessage.listen(
        (message) => unawaited(
          _notificationDisplayService.showForegroundNotification(message),
        ),
      );
      _tokenRefreshSubscription = _deviceTokenProvider.onTokenRefresh.listen(
        (token) => unawaited(_handleTokenRefresh(token)),
      );
      _notificationOpenedSubscription = _deviceTokenProvider.onMessageOpenedApp
          .listen(
            (message) => unawaited(
              _handleTapPayload(
                NotificationTapPayloadModel.fromMessageData(message.data),
              ),
            ),
          );
      _localTapSubscription = _notificationDisplayService.onNotificationTap.listen(
        (payload) => unawaited(_handleTapPayload(payload)),
      );
      unawaited(_consumeInitialMessage());
    } catch (_) {
      // Widget tests can boot without Firebase initialized.
    }
  }

  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _notificationOpenedSubscription?.cancel();
    _localTapSubscription?.cancel();
  }

  Future<void> _consumeInitialMessage() async {
    final message = await _deviceTokenProvider.getInitialMessage();
    if (message == null) {
      return;
    }

    await _handleTapPayload(
      NotificationTapPayloadModel.fromMessageData(message.data),
    );
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    if (newToken.isEmpty) {
      debugPrint('[FCM] Token refresh delivered an empty token.');
      return;
    }

    debugPrint('[FCM] Firebase token refreshed: $newToken');

    final authToken = await _tokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) {
      debugPrint('[FCM] Skipping token refresh registration because auth token is missing.');
      return;
    }

    final previousToken = await _deviceTokenStorage.getToken();
    debugPrint('[FCM] Previously saved token: ${previousToken ?? '(none)'}');
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
    } catch (error) {
      debugPrint('[FCM] Token refresh registration failed: $error');
      // Token refresh registration is best-effort.
    }
  }

  Future<void> _handleTapPayload(NotificationTapPayloadModel payload) async {
    final notificationId = payload.notificationId;
    final entityType = payload.entityType;
    final entityId = payload.entityId;

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

  @visibleForTesting
  Future<void> debugHandleTapPayload(NotificationTapPayloadModel payload) {
    return _handleTapPayload(payload);
  }
}
