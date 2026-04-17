import 'package:firebase_messaging/firebase_messaging.dart';

abstract class DeviceTokenProvider {
  Future<void> requestPermission() async {}
  Future<String?> getToken();
  Future<RemoteMessage?> getInitialMessage() async => null;
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
  Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream<RemoteMessage>.empty();
}

class FirebaseDeviceTokenProvider implements DeviceTokenProvider {
  FirebaseDeviceTokenProvider({FirebaseMessaging? messaging})
    : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  FirebaseMessaging get _resolvedMessaging =>
      _messaging ?? FirebaseMessaging.instance;

  @override
  Future<void> requestPermission() async {
    await _resolvedMessaging.requestPermission();
  }

  @override
  Future<String?> getToken() {
    return _resolvedMessaging.getToken();
  }

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return _resolvedMessaging.getInitialMessage();
  }

  @override
  Stream<String> get onTokenRefresh => _resolvedMessaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
