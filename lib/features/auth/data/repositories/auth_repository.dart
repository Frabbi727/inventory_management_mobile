import 'dart:io';

import '../../../../core/storage/device_token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/device_register_model.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/logout_response_model.dart';
import '../models/profile_response_model.dart';
import '../services/device_token_provider.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required DeviceTokenProvider deviceTokenProvider,
    required DeviceTokenStorage deviceTokenStorage,
  }) : _apiClient = apiClient,
       _deviceTokenProvider = deviceTokenProvider,
       _deviceTokenStorage = deviceTokenStorage;

  final ApiClient _apiClient;
  final DeviceTokenProvider _deviceTokenProvider;
  final DeviceTokenStorage _deviceTokenStorage;

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
    );

    final loginResponse = LoginResponseModel.fromJson(response);
    final authToken = loginResponse.data?.token;
    if (authToken != null && authToken.isNotEmpty) {
      await _registerCurrentDevice(authToken);
    }

    return loginResponse;
  }

  Future<ProfileResponseModel> getCurrentProfile(String token) async {
    final response = await _apiClient.get(ApiEndpoints.me, token: token);

    return ProfileResponseModel.fromJson(response);
  }

  Future<LogoutResponseModel> logout(String token) async {
    try {
      await unregisterCurrentDevice(token);
    } catch (_) {
      // Device unregistration should not block logout.
    }

    final response = await _apiClient.post(ApiEndpoints.logout, token: token);

    return LogoutResponseModel.fromJson(response);
  }

  Future<void> registerCurrentDeviceForSession(String authToken) async {
    await _registerCurrentDevice(authToken);
  }

  Future<void> registerSpecificDeviceForSession(
    String authToken,
    String deviceToken,
  ) async {
    await _registerDevice(authToken, deviceToken);
  }

  Future<void> unregisterCurrentDevice(String authToken) async {
    final savedToken = await _deviceTokenStorage.getToken();
    if (savedToken == null || savedToken.isEmpty) {
      return;
    }

    await unregisterSpecificDevice(authToken, savedToken);
    await _deviceTokenStorage.clearToken();
  }

  Future<void> unregisterSpecificDevice(
    String authToken,
    String deviceToken,
  ) async {
    await _apiClient.post(
      ApiEndpoints.deviceUnregister,
      token: authToken,
      body: <String, dynamic>{'device_token': deviceToken},
    );
  }

  Future<void> _registerCurrentDevice(String authToken) async {
    try {
      await _deviceTokenProvider.requestPermission();
      final deviceToken = await _deviceTokenProvider.getToken();
      if (deviceToken == null || deviceToken.isEmpty) {
        return;
      }

      await _registerDevice(authToken, deviceToken);
    } catch (_) {
      // Device registration is best-effort and should not block login.
    }
  }

  Future<void> _registerDevice(String authToken, String deviceToken) async {
    await _deviceTokenStorage.saveToken(deviceToken);
    await _apiClient.post(
      ApiEndpoints.deviceRegister,
      token: authToken,
      body: DeviceRegisterModel(
        deviceToken: deviceToken,
        platform: _resolvePlatform(),
        deviceName: 'salesman-phone',
      ).toJson(),
    );
  }

  String _resolvePlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return Platform.operatingSystem;
  }
}
