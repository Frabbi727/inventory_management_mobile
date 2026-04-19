import 'dart:async';
import 'dart:convert';

import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/device_token_storage.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/auth/data/repositories/auth_repository.dart';
import 'package:b2b_inventory_management/features/auth/data/services/device_token_provider.dart';
import 'package:b2b_inventory_management/features/notifications/data/models/notification_tap_payload_model.dart';
import 'package:b2b_inventory_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:b2b_inventory_management/features/notifications/data/services/notification_display_service.dart';
import 'package:b2b_inventory_management/features/notifications/data/services/notification_lifecycle_service.dart';
import 'package:b2b_inventory_management/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeDeviceTokenProvider extends DeviceTokenProvider {
  final _foregroundController = StreamController<RemoteMessage>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();
  final _openedController = StreamController<RemoteMessage>.broadcast();

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<RemoteMessage> get onMessage => _foregroundController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _openedController.stream;

  void emitForeground(RemoteMessage message) {
    _foregroundController.add(message);
  }
}

class _FakeNotificationDisplayService extends NotificationDisplayService {
  _FakeNotificationDisplayService();

  final _tapController = StreamController<NotificationTapPayloadModel>.broadcast();
  final shownMessages = <RemoteMessage>[];
  var initialized = false;

  @override
  Stream<NotificationTapPayloadModel> get onNotificationTap =>
      _tapController.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> showForegroundNotification(RemoteMessage message) async {
    shownMessages.add(message);
  }

  void emitTap(NotificationTapPayloadModel payload) {
    _tapController.add(payload);
  }
}

class _FakeNotificationController extends NotificationController {
  _FakeNotificationController({required super.notificationRepository});

  int? markedNotificationId;
  var unreadRefreshes = 0;
  var reloads = 0;

  @override
  Future<void> markAsReadById(int notificationId) async {
    markedNotificationId = notificationId;
  }

  @override
  Future<void> refreshUnreadCount() async {
    unreadRefreshes++;
  }

  @override
  Future<void> refreshIfLoaded() async {
    reloads++;
  }
}

NotificationRepository _createNotificationRepository() {
  return NotificationRepository(
    apiClient: ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/unread-count')) {
          return http.Response(
            jsonEncode({'count': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({'message': 'OK'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
    tokenStorage: TokenStorage(),
  );
}

AuthRepository _createAuthRepository(DeviceTokenProvider provider) {
  return AuthRepository(
    apiClient: ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'OK'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    ),
    deviceTokenProvider: provider,
    deviceTokenStorage: DeviceTokenStorage(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  test('foreground FCM message is delegated to the display service', () async {
    final provider = _FakeDeviceTokenProvider();
    final displayService = _FakeNotificationDisplayService();
    final lifecycleService = NotificationLifecycleService(
      deviceTokenProvider: provider,
      notificationDisplayService: displayService,
      tokenStorage: TokenStorage(),
      deviceTokenStorage: DeviceTokenStorage(),
      authRepository: _createAuthRepository(provider),
    );

    await lifecycleService.ensureInitialized();

    provider.emitForeground(
      RemoteMessage(
        data: const {'notification_id': '101', 'entity_type': 'order', 'entity_id': '55'},
        notification: const RemoteNotification(
          title: 'Order confirmed',
          body: 'Your order ORD-1005 has been confirmed.',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(displayService.initialized, isTrue);
    expect(displayService.shownMessages, hasLength(1));
    expect(displayService.shownMessages.first.data['notification_id'], '101');
  });

  test('local notification tap is routed through the notification controller', () async {
    final provider = _FakeDeviceTokenProvider();
    final displayService = _FakeNotificationDisplayService();
    final fakeController = _FakeNotificationController(
      notificationRepository: _createNotificationRepository(),
    );
    Get.put<NotificationController>(fakeController);

    final lifecycleService = NotificationLifecycleService(
      deviceTokenProvider: provider,
      notificationDisplayService: displayService,
      tokenStorage: TokenStorage(),
      deviceTokenStorage: DeviceTokenStorage(),
      authRepository: _createAuthRepository(provider),
    );

    await lifecycleService.ensureInitialized();
    displayService.emitTap(
      const NotificationTapPayloadModel(
        notificationId: 101,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(fakeController.markedNotificationId, 101);
    expect(fakeController.unreadRefreshes, greaterThanOrEqualTo(1));
    expect(fakeController.reloads, 1);
  });
}
