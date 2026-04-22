import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/constants/api_config.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/models/create_order_request_model.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/models/order_item_request_model.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_repository.dart';
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
            equals('${ApiConfig.baseUrl}/api/orders'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer order-token'),
          );

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['customer_id'], equals(2));
          expect(
            body['intended_delivery_at'],
            equals('2026-04-09T15:30:00+06:00'),
          );
          expect(body['discount_type'], equals('amount'));
          expect(body['discount_value'], equals(100));
          expect(body['payment_amount'], equals(1300));
          expect(body['items'], isA<List<dynamic>>());

          return http.Response(
            jsonEncode({
              'message': 'Order created successfully.',
              'data': {
                'id': 99,
                'order_no': 'ORD-ABC12345',
                'grand_total': 1400,
                'payment_amount': 1300,
                'payment_status': 'partial',
                'due_amount': 100,
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
        intendedDeliveryAt: '2026-04-09T15:30:00+06:00',
        note: 'Deliver quickly',
        discountType: 'amount',
        discountValue: 100,
        paymentAmount: 1300,
        items: [OrderItemRequestModel(productId: 1, quantity: 2)],
      ),
    );

    expect(response.message, equals('Order created successfully.'));
    expect(response.data?.orderNo, equals('ORD-ABC12345'));
    expect(response.data?.paymentAmount, equals(1300));
    expect(response.data?.paymentStatus, equals('partial'));
    expect(response.data?.dueAmount, equals(100));
  });

  test('fetchOrders sends page query with auth header', () async {
    final repository = OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(
            request.url.toString(),
            equals('${ApiConfig.baseUrl}/api/orders?page=2'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer order-token'),
          );

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 2,
                  'order_no': 'ORD-NHPXCXHK',
                  'order_date': '2026-04-07T00:00:00.000000Z',
                  'intended_delivery_at': '2026-04-08T09:00:00.000000Z',
                  'confirmed_at': '2026-04-07T10:15:00.000000Z',
                  'delivered_at': '2026-04-07T10:15:00.000000Z',
                  'grand_total': 85,
                  'payment_amount': 85,
                  'payment_status': 'paid',
                  'due_amount': 0,
                  'status': 'confirmed',
                  'customer': {
                    'id': 2,
                    'name': 'Bismillah Traders',
                    'phone': '+8801710001002',
                  },
                  'salesman': {'id': 2, 'name': 'Sales Demo'},
                  'items': const [],
                },
              ],
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

    final response = await repository.fetchOrders(page: 2);

    expect(response.data?.single.orderNo, equals('ORD-NHPXCXHK'));
    expect(
      response.data?.single.intendedDeliveryAt,
      equals('2026-04-08T09:00:00.000000Z'),
    );
  });

  test('fetchOrders sends supported mobile search and due filters', () async {
    final repository = OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.queryParameters['page'], equals('3'));
          expect(request.url.queryParameters['q'], equals('rahman'));
          expect(request.url.queryParameters['status'], equals('draft'));
          expect(
            request.url.queryParameters['start_date'],
            equals('2026-04-01'),
          );
          expect(request.url.queryParameters['end_date'], equals('2026-04-30'));
          expect(
            request.url.queryParameters['intended_delivery_start'],
            equals('2026-04-10'),
          );
          expect(
            request.url.queryParameters['intended_delivery_end'],
            equals('2026-04-20'),
          );
          expect(
            request.url.queryParameters['delivery_state'],
            equals('overdue'),
          );
          expect(
            request.url.queryParameters['payment_status'],
            equals('partial'),
          );
          expect(
            request.url.queryParameters.containsKey('customer_id'),
            isFalse,
          );

          return http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 3, 'last_page': 3},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    await repository.fetchOrders(
      page: 3,
      query: 'rahman',
      status: 'draft',
      startDate: '2026-04-01',
      endDate: '2026-04-30',
      intendedDeliveryStart: '2026-04-10',
      intendedDeliveryEnd: '2026-04-20',
      deliveryState: 'overdue',
      paymentStatus: 'partial',
    );
  });

  test('fetchOrderDetails sends order id with auth header', () async {
    final repository = OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(
            request.url.toString(),
            equals('${ApiConfig.baseUrl}/api/orders/6'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer order-token'),
          );

          return http.Response(
            jsonEncode({
              'data': {
                'id': 6,
                'order_no': 'ORD-0006',
                'order_date': '2026-04-08',
                'intended_delivery_at': '2026-04-08T13:45:00.000000Z',
                'confirmed_at': '2026-04-08T14:00:00.000000Z',
                'delivered_at': '2026-04-08T14:00:00.000000Z',
                'grand_total': 140,
                'status': 'confirmed',
                'customer': {
                  'id': 1,
                  'name': 'Rahman Store',
                  'phone': '+8801710001001',
                },
                'salesman': {'id': 2, 'name': 'Sales Demo'},
                'items': const [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchOrderDetails(6);

    expect(response.data?.orderNo, equals('ORD-0006'));
    expect(response.data?.confirmedAt, equals('2026-04-08T14:00:00.000000Z'));
  });

  test('confirmOrder posts to confirm endpoint', () async {
    final repository = OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('${ApiConfig.baseUrl}/api/orders/9/confirm'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer order-token'),
          );

          return http.Response(
            jsonEncode({
              'message': 'Order confirmed successfully.',
              'data': {'id': 9, 'order_no': 'ORD-009', 'status': 'confirmed'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.confirmOrder(9);

    expect(response.data?.status, equals('confirmed'));
  });
}
