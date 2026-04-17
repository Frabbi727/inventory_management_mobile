import 'package:shared_preferences/shared_preferences.dart';

class DeviceTokenStorage {
  static const _deviceTokenKey = 'fcm_device_token';

  Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceTokenKey, token);
  }

  Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_deviceTokenKey);
  }

  Future<void> clearToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceTokenKey);
  }
}
