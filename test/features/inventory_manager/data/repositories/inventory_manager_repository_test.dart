import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/repositories/inventory_manager_repository.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'inventory-token',
    });
  });

  test('fetchSubcategories sends category_id filter', () async {
    late http.Request capturedRequest;
    final repository = InventoryManagerRepository(
      productRepository: ProductRepository(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      ),
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'name': 'Samsung', 'category_id': 1},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchSubcategories(categoryId: 1);

    expect(capturedRequest.url.path, '/api/subcategories');
    expect(capturedRequest.url.queryParameters['category_id'], '1');
    expect(response.first.name, 'Samsung');
  });
}
