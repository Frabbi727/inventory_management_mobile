import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/errors/api_exception.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/customers/data/models/create_customer_request_model.dart';
import 'package:b2b_inventory_management/features/customers/data/repositories/customer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'customer-token',
    });
  });

  test('fetchCustomers sends page and q query parameters', () async {
    late http.Request capturedRequest;
    final repository = CustomerRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 2, 'last_page': 2},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    await repository.fetchCustomers(page: 2, query: 'rah');

    expect(capturedRequest.headers['X-Authorization'], 'Bearer customer-token');
    expect(capturedRequest.url.path, '/api/customers');
    expect(capturedRequest.url.queryParameters['page'], '2');
    expect(capturedRequest.url.queryParameters['q'], 'rah');
  });

  test('createCustomer sends expected request payload', () async {
    late http.Request capturedRequest;
    final repository = CustomerRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'message': 'Customer created successfully.',
              'data': {'id': 5, 'name': 'Rahman Store'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    await repository.createCustomer(
      const CreateCustomerRequestModel(
        name: 'Rahman Store',
        phone: '01710001001',
        address: '12 Lake Circus, Dhaka',
        area: 'Dhanmondi',
      ),
    );

    expect(capturedRequest.url.path, '/api/customers');
    expect(jsonDecode(capturedRequest.body), {
      'name': 'Rahman Store',
      'phone': '01710001001',
      'address': '12 Lake Circus, Dhaka',
      'area': 'Dhanmondi',
    });
  });

  test('customer repository throws when token is missing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = CustomerRepository(
      apiClient: ApiClient(
        httpClient: MockClient((_) async {
          throw StateError('HTTP client should not be called without token.');
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    expect(
      () => repository.fetchCustomers(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
