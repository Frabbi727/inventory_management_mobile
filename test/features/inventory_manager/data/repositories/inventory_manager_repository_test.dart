import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/repositories/inventory_manager_repository.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';
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

  test('fetchInventoryDashboard sends inventory dashboard request', () async {
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
              'data': {
                'summary': {
                  'total_active_products': 120,
                  'all_count': 120,
                  'low_stock_count': 8,
                  'out_of_stock_count': 3,
                  'in_stock_count': 109,
                  'products_added_today': 4,
                  'purchases_created_today': 2,
                  'purchase_value_today': 5400,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchInventoryDashboard();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/api/dashboard/inventory-manager');
    expect(capturedRequest.headers['X-Authorization'], 'Bearer inventory-token');
    expect(response.success, isTrue);
    expect(response.data?.summary?.allCount, 120);
    expect(response.data?.summary?.inStockCount, 109);
    expect(response.data?.summary?.purchaseValueToday, 5400);
  });

  test('fetchInventoryProducts sends stock filter, query and paging', () async {
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
              'data': {
                'products': {
                  'data': [
                    {
                      'id': 12,
                      'name': 'Milk Pack',
                      'sku': 'MILK-001',
                      'current_stock': 0,
                      'minimum_stock_alert': 5,
                      'stock_status': 'out_of_stock',
                      'status': 'active',
                    },
                  ],
                  'current_page': 1,
                  'per_page': 10,
                  'total': 3,
                  'last_page': 1,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchInventoryProducts(
      stockFilter: 'out_of_stock',
      query: 'milk',
      page: 1,
      perPage: 10,
    );

    expect(capturedRequest.url.path, '/api/inventory/products');
    expect(capturedRequest.url.queryParameters['stock_filter'], 'out_of_stock');
    expect(capturedRequest.url.queryParameters['q'], 'milk');
    expect(capturedRequest.url.queryParameters['page'], '1');
    expect(capturedRequest.url.queryParameters['per_page'], '10');
    expect(response.data?.products?.data?.single.name, 'Milk Pack');
    expect(response.data?.products?.total, 3);
  });
}
