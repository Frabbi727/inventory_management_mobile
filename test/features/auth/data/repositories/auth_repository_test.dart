import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/errors/api_exception.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/device_token_storage.dart';
import 'package:b2b_inventory_management/features/auth/data/models/login_request_model.dart';
import 'package:b2b_inventory_management/features/auth/data/repositories/auth_repository.dart';
import 'package:b2b_inventory_management/features/auth/data/services/device_token_provider.dart';

class _FakeDeviceTokenProvider extends DeviceTokenProvider {
  _FakeDeviceTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

class _FakeDeviceTokenStorage extends DeviceTokenStorage {
  String? savedToken;
  bool cleared = false;

  @override
  Future<void> saveToken(String token) async {
    savedToken = token;
  }

  @override
  Future<String?> getToken() async => savedToken;

  @override
  Future<void> clearToken() async {
    cleared = true;
    savedToken = null;
  }
}

void main() {
  test('login sends expected JSON payload', () async {
    late http.Request capturedRequest;
    final deviceTokenStorage = _FakeDeviceTokenStorage();
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'message': 'Login successful.',
              'data': {'token': 'abc123'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider(null),
      deviceTokenStorage: deviceTokenStorage,
    );

    await repository.login(
      const LoginRequestModel(
        login: 'salesman@example.com',
        password: 'secret',
        deviceName: 'flutter-mobile',
      ),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/login');
    expect(jsonDecode(capturedRequest.body), {
      'login': 'salesman@example.com',
      'password': 'secret',
      'device_name': 'flutter-mobile',
    });
  });

  test('protected profile request uses X-Authorization header', () async {
    late http.Request capturedRequest;
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': {'id': 2, 'name': 'Sales Demo'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider(null),
      deviceTokenStorage: _FakeDeviceTokenStorage(),
    );

    await repository.getCurrentProfile('secure-token');

    expect(
      capturedRequest.headers['X-Authorization'],
      equals('Bearer secure-token'),
    );
    expect(capturedRequest.url.path, '/api/me');
  });

  test('validation failures propagate as ApiException with errors', () async {
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'login': ['Login is required.'],
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider(null),
      deviceTokenStorage: _FakeDeviceTokenStorage(),
    );

    expect(
      () => repository.login(const LoginRequestModel()),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              'The given data was invalid.',
            )
            .having((error) => error.errors?['login'], 'errors', [
              'Login is required.',
            ]),
      ),
    );
  });

  test('login registers current device when an FCM token is available', () async {
    final requests = <http.Request>[];
    final deviceTokenStorage = _FakeDeviceTokenStorage();
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/login') {
            return http.Response(
              jsonEncode({
                'message': 'Login successful.',
                'data': {
                  'token': 'abc123',
                  'user': {'id': 7, 'name': 'Sales Demo'},
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode({'message': 'Device registered'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider('fcm-token'),
      deviceTokenStorage: deviceTokenStorage,
    );

    await repository.login(
      const LoginRequestModel(login: 'salesman@example.com', password: 'secret'),
    );

    expect(requests, hasLength(2));
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/api/devices/register');
    expect(requests.last.headers['X-Authorization'], 'Bearer abc123');
    expect(jsonDecode(requests.last.body), {
      'device_token': 'fcm-token',
      'platform': isA<String>(),
      'device_name': 'salesman-phone',
    });
    expect(deviceTokenStorage.savedToken, 'fcm-token');
  });

  test('login still succeeds when device registration fails', () async {
    final requests = <http.Request>[];
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/login') {
            return http.Response(
              jsonEncode({
                'message': 'Login successful.',
                'data': {
                  'token': 'abc123',
                  'user': {'id': 7, 'name': 'Sales Demo'},
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode({'message': 'Registration failed'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider('fcm-token'),
      deviceTokenStorage: _FakeDeviceTokenStorage(),
    );

    final response = await repository.login(
      const LoginRequestModel(login: 'salesman@example.com', password: 'secret'),
    );

    expect(response.data?.token, 'abc123');
    expect(requests.map((request) => request.url.path).toList(), [
      '/api/login',
      '/api/devices/register',
    ]);
  });

  test('logout unregisters device before logout when a token is stored', () async {
    final requests = <http.Request>[];
    final deviceTokenStorage = _FakeDeviceTokenStorage()..savedToken = 'fcm-token';
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'message': 'OK'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider(null),
      deviceTokenStorage: deviceTokenStorage,
    );

    await repository.logout('secure-token');

    expect(requests.map((request) => request.url.path).toList(), [
      '/api/devices/unregister',
      '/api/logout',
    ]);
    expect(jsonDecode(requests.first.body), {'device_token': 'fcm-token'});
    expect(deviceTokenStorage.cleared, isTrue);
  });

  test('logout still calls logout when device unregister fails', () async {
    final requests = <http.Request>[];
    final repository = AuthRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/devices/unregister') {
            return http.Response(
              jsonEncode({'message': 'Failed'}),
              500,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode({'message': 'Logout successful.'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      deviceTokenProvider: _FakeDeviceTokenProvider(null),
      deviceTokenStorage: _FakeDeviceTokenStorage()..savedToken = 'fcm-token',
    );

    final response = await repository.logout('secure-token');

    expect(response.message, 'Logout successful.');
    expect(requests.map((request) => request.url.path).toList(), [
      '/api/devices/unregister',
      '/api/logout',
    ]);
  });
}
