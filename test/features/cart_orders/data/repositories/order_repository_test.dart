import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/cart_orders/data/models/create_order_request_model.dart';
import 'package:inventory_management_sales/features/cart_orders/data/models/order_item_request_model.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'order-token',
    });
  });

  test('createOrder sends expected payload with auth header', () async {
    final repository = OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('https://ordermanage.b2bhaat.com/api/orders'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer order-token'),
          );

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['customer_id'], equals(2));
          expect(body['discount_type'], equals('amount'));
          expect(body['discount_value'], equals(100));
          expect(body['items'], isA<List<dynamic>>());

          return http.Response(
            jsonEncode({
              'message': 'Order created successfully.',
              'data': {
                'id': 99,
                'order_no': 'ORD-ABC12345',
                'grand_total': 1400,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.createOrder(
      const CreateOrderRequestModel(
        customerId: 2,
        orderDate: '2026-04-09',
        note: 'Deliver quickly',
        discountType: 'amount',
        discountValue: 100,
        items: [OrderItemRequestModel(productId: 1, quantity: 2)],
      ),
    );

    expect(response.message, equals('Order created successfully.'));
    expect(response.data?.orderNo, equals('ORD-ABC12345'));
  });
}
