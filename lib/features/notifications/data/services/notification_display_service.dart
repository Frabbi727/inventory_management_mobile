import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_tap_payload_model.dart';

class NotificationDisplayService {
  NotificationDisplayService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'sales_notifications';
  static const _channelName = 'Sales Notifications';
  static const _channelDescription =
      'Foreground notifications for sales updates.';

  final FlutterLocalNotificationsPlugin _plugin;
  final _tapPayloadController = StreamController<NotificationTapPayloadModel>.broadcast();
  bool _isInitialized = false;

  Stream<NotificationTapPayloadModel> get onNotificationTap =>
      _tapPayloadController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = NotificationTapPayloadModel.fromPayloadString(
          response.payload,
        );
        if (payload != null) {
          _tapPayloadController.add(payload);
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ),
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final tapPayload = NotificationTapPayloadModel.fromMessageData(message.data);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _notificationIdForMessage(message),
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(tapPayload.toJson()),
    );
  }

  int _notificationIdForMessage(RemoteMessage message) {
    final payload = NotificationTapPayloadModel.fromMessageData(message.data);
    return payload.notificationId ?? message.messageId.hashCode;
  }
}
