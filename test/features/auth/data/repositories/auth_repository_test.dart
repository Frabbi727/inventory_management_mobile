import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/errors/api_exception.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/features/auth/data/models/login_request_model.dart';
import 'package:inventory_management_sales/features/auth/data/repositories/auth_repository.dart';

void main() {
  test('login sends expected JSON payload', () async {
    late http.Request capturedRequest;
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
}
