import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/errors/api_exception.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/network/api_logger.dart';

class FakeApiLogger extends ApiLogger {
  FakeApiLogger();

  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];
  final List<Map<String, Object?>> responses = <Map<String, Object?>>[];
  final List<Map<String, Object?>> errors = <Map<String, Object?>>[];

  @override
  void logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    requests.add({
      'method': method,
      'uri': uri,
      'headers': headers,
      'body': body,
    });
  }

  @override
  void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    responses.add({
      'method': method,
      'uri': uri,
      'statusCode': statusCode,
      'headers': headers,
      'body': body,
    });
  }

  @override
  void logErrorResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    errors.add({
      'method': method,
      'uri': uri,
      'statusCode': statusCode,
      'headers': headers,
      'body': body,
    });
  }
}

void main() {
  test(
    'get request still parses success responses with logging enabled',
    () async {
      late http.Request capturedRequest;
      final logger = FakeApiLogger();
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': {'id': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        apiLogger: logger,
      );

      final response = await apiClient.get('/api/me', token: 'abc123');

      expect(response['data']['id'], 1);
      expect(capturedRequest.headers['X-Authorization'], 'Bearer abc123');
      expect(logger.requests, hasLength(1));
      expect(logger.responses, hasLength(1));
      expect(logger.errors, isEmpty);
      expect(logger.requests.first['method'], 'GET');
      expect(logger.responses.first['statusCode'], 200);
    },
  );

  test('post request still sends body and logs request details', () async {
    late http.Request capturedRequest;
    final logger = FakeApiLogger();
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'message': 'Login successful.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      apiLogger: logger,
    );

    await apiClient.post(
      '/api/login',
      body: {'login': 'salesman@example.com', 'password': 'secret'},
    );

    expect(jsonDecode(capturedRequest.body), {
      'login': 'salesman@example.com',
      'password': 'secret',
    });
    expect(logger.requests.first['body'], {
      'login': 'salesman@example.com',
      'password': 'secret',
    });
    expect(logger.responses, hasLength(1));
  });

  test('error responses still throw ApiException and are logged', () async {
    final logger = FakeApiLogger();
    final apiClient = ApiClient(
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
      apiLogger: logger,
    );

    await expectLater(
      () => apiClient.get('/api/me', token: 'bad-token'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(logger.requests, hasLength(1));
    expect(logger.responses, isEmpty);
    expect(logger.errors, hasLength(1));
    expect(logger.errors.first['statusCode'], 401);
  });
}
