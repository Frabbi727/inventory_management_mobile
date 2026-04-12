import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/errors/api_exception.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/products/data/models/product_details_response_model.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'product-token',
    });
  });

  test(
    'fetchProducts sends page, status, q, category, and subcategory query parameters',
    () async {
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

    await repository.fetchProducts(
      page: 2,
      query: 'milk',
      categoryId: 8,
      subcategoryId: 11,
    );

    expect(
      capturedRequest.headers['X-Authorization'],
      equals('Bearer product-token'),
    );
    expect(capturedRequest.url.path, '/api/products');
    expect(capturedRequest.url.queryParameters['page'], '2');
    expect(capturedRequest.url.queryParameters['status'], 'active');
    expect(capturedRequest.url.queryParameters['q'], 'milk');
    expect(capturedRequest.url.queryParameters['category_id'], '8');
    expect(capturedRequest.url.queryParameters['subcategory_id'], '11');
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

  test(
    'fetchProducts reuses cached responses for the same page and query',
    () async {
      var callCount = 0;
      final repository = ProductRepository(
        apiClient: ApiClient(
          httpClient: MockClient((request) async {
            callCount += 1;
            return http.Response(
              jsonEncode({
                'data': const [],
                'links': {'next': null},
                'meta': {'current_page': 1, 'last_page': 1},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
        tokenStorage: TokenStorage(),
      );

      await repository.fetchProducts(page: 1);
      await repository.fetchProducts(page: 1);

      expect(callCount, 1);
    },
  );

  test('fetchProducts forceRefresh bypasses the cache', () async {
    var callCount = 0;
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          callCount += 1;
          return http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 1, 'last_page': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    await repository.fetchProducts(page: 1);
    await repository.fetchProducts(page: 1, forceRefresh: true);

    expect(callCount, 2);
  });

  test('fetchProductDetails sends the product details request', () async {
    late http.Request capturedRequest;
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 7,
                'name': 'Head Phone',
                'sku': 'head_phone',
                'barcode': 'head_phone',
                'barcode_image_url': 'https://example.com/barcode.svg',
                'selling_price': 1999.99,
                'current_stock': 0,
                'photos': [
                  {
                    'id': 1,
                    'file_name': 'head-phone.png',
                    'file_url': 'https://example.com/head-phone.png',
                    'is_primary': true,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchProductDetails(7);

    expect(capturedRequest.url.path, '/api/products/7');
    expect(
      response.data?.photos?.first.fileUrl,
      'https://example.com/head-phone.png',
    );
    expect(response.data?.barcodeImageUrl, 'https://example.com/barcode.svg');
  });

  test('fetchProductDetails parses optional variant and subcategory fields', () async {
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 1,
                'name': 'Samsung S28',
                'has_variants': true,
                'subcategory': {
                  'id': 1,
                  'name': 'Samsung',
                  'category_id': 1,
                },
                'variant_summary': {
                  'total_variants': 3,
                  'in_stock_count': 0,
                  'low_stock_count': 0,
                  'out_of_stock_count': 3,
                },
                'variant_attributes': [
                  {
                    'id': 4,
                    'name': 'Storage',
                    'values': ['128', '256'],
                  },
                ],
                'variants': [
                  {
                    'id': 9,
                    'combination_key': 'storage-128',
                    'combination_label': '128',
                    'option_values': {'Storage': '128'},
                    'is_active': true,
                    'current_stock': 0,
                    'stock_status': 'out_of_stock',
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchProductDetails(1);

    expect(response.data?.hasVariants, isTrue);
    expect(response.data?.subcategory?.name, 'Samsung');
    expect(response.data?.variantSummary?.totalVariants, 3);
    expect(response.data?.variantAttributes?.first.values, ['128', '256']);
    expect(response.data?.variants?.first.combinationKey, 'storage-128');
  });

  test('fetchProductDetails accepts direct product objects too', () async {
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'id': 5,
              'name': 'Dishwashing Liquid 500ml',
              'sku': 'PRD-DISH-500',
              'barcode': 'PRD-DISH-500',
              'barcode_image_url': 'https://example.com/dish.svg',
              'selling_price': 85,
              'current_stock': 924,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final ProductDetailsResponseModel response = await repository
        .fetchProductDetails(5);

    expect(response.data?.id, 5);
    expect(response.data?.barcode, 'PRD-DISH-500');
  });

  test('fetchProductDetails rewrites localhost media URLs to API host', () async {
    final repository = ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 7,
                'name': 'Orimo Open air',
                'sku': 'orimo_open_air',
                'barcode': 'orimo_open_air',
                'barcode_image_url':
                    'http://localhost/storage/products/orimo-open-air/barcode/barcode.svg',
                'primary_photo': {
                  'id': 1,
                  'file_url':
                      'http://localhost/storage/products/orimo-open-air/photos/01.png',
                  'is_primary': true,
                },
                'photos': [
                  {
                    'id': 1,
                    'file_url':
                        'http://localhost/storage/products/orimo-open-air/photos/01.png',
                    'is_primary': true,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchProductDetails(7);

    expect(
      response.data?.barcodeImageUrl,
      'http://192.168.0.129:8000/storage/products/orimo-open-air/barcode/barcode.svg',
    );
    expect(
      response.data?.primaryPhoto?.fileUrl,
      'http://192.168.0.129:8000/storage/products/orimo-open-air/photos/01.png',
    );
    expect(
      response.data?.photos?.first.fileUrl,
      'http://192.168.0.129:8000/storage/products/orimo-open-air/photos/01.png',
    );
  });
}
