import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/errors/api_exception.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'product-token',
    });
  });

  test('fetchProducts sends page, status, and q query parameters', () async {
    late http.Request capturedRequest;
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 2, 'last_page': 3},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    await repository.fetchProducts(page: 2, query: 'milk');

    expect(
      capturedRequest.headers['X-Authorization'],
      equals('Bearer product-token'),
    );
    expect(capturedRequest.url.path, '/api/products');
    expect(capturedRequest.url.queryParameters['page'], '2');
    expect(capturedRequest.url.queryParameters['status'], 'active');
    expect(capturedRequest.url.queryParameters['q'], 'milk');
  });

  test('fetchProducts throws when token is missing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((_) async {
          throw StateError('HTTP client should not be called without token.');
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    expect(
      () => repository.fetchProducts(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
