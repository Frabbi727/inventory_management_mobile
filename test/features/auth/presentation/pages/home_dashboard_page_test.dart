import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/app.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/auth/data/repositories/auth_repository.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:inventory_management_sales/features/customers/data/repositories/customer_repository.dart';
import 'package:inventory_management_sales/features/dashboard/data/repositories/salesman_dashboard_repository.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  AuthRepository createAuthRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return AuthRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
    );
  }

  ProductRepository createProductRepository() {
    return ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 1, 'last_page': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  CustomerRepository createCustomerRepository() {
    return CustomerRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': const [],
              'links': {'next': null},
              'meta': {'current_page': 1, 'last_page': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  OrderRepository createOrderRepository() {
    return OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/orders')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 11,
                    'order_no': 'ORD-2026-001',
                    'order_date': '2026-04-17',
                    'grand_total': 139,
                    'status': 'confirmed',
                    'customer': {
                      'id': 1,
                      'name': 'Rahman Store',
                      'phone': '+8801710001001',
                    },
                    'items': const [],
                  },
                ],
                'links': {'next': null},
                'meta': {'current_page': 1, 'last_page': 1},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode({
              'data': {
                'id': 11,
                'order_no': 'ORD-2026-001',
                'order_date': '2026-04-17',
                'grand_total': 139,
                'status': 'confirmed',
                'customer': {
                  'id': 1,
                  'name': 'Rahman Store',
                  'phone': '+8801710001001',
                },
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
  }

  SalesmanDashboardRepository createDashboardRepository(
    List<Map<String, String>> capturedQueries,
  ) {
    return SalesmanDashboardRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          capturedQueries.add(request.url.queryParameters);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'filters': {
                  'range': request.url.queryParameters['range'] ?? 'today',
                  'start_date': '2026-04-17',
                  'end_date': '2026-04-17',
                },
                'summary': {
                  'sales_amount': 980,
                  'total_orders_count': 4,
                  'draft_orders_count': 1,
                  'confirmed_orders_count': 3,
                  'overdue_deliveries_count': 1,
                },
                'next_due_orders': [
                  {
                    'id': 1,
                    'order_no': 'ORD-1001',
                    'status': 'draft',
                    'order_date': '2026-04-17',
                    'intended_delivery_at': '2026-04-18T10:30:00+06:00',
                    'grand_total': 1250.0,
                    'customer': {
                      'id': 5,
                      'name': 'Rahim Store',
                      'phone': '01711000000',
                    },
                  },
                ],
                'recent_orders': [
                  {
                    'id': 2,
                    'order_no': 'ORD-1002',
                    'status': 'confirmed',
                    'order_date': '2026-04-17',
                    'intended_delivery_at': '2026-04-19T11:00:00+06:00',
                    'grand_total': 980.0,
                    'customer': {
                      'id': 8,
                      'name': 'Karim Traders',
                      'phone': '01822000000',
                    },
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
  }

  testWidgets(
    'home dashboard loads today and refreshes when returning to Home',
    (WidgetTester tester) async {
      final capturedDashboardQueries = <Map<String, String>>[];

      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'shell-token',
      });

      Get.put<AuthRepository>(
        createAuthRepository((request) async {
          if (request.url.path.endsWith('/me')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 2,
                  'name': 'Sales Demo',
                  'email': 'salesman@example.com',
                  'phone': '+8801700000002',
                  'role': {'id': 2, 'name': 'Salesman', 'slug': 'salesman'},
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode({'message': 'Logout successful.'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      Get.put<ProductRepository>(createProductRepository(), permanent: true);
      Get.put<CustomerRepository>(createCustomerRepository(), permanent: true);
      Get.put<OrderRepository>(createOrderRepository(), permanent: true);
      Get.put<SalesmanDashboardRepository>(
        createDashboardRepository(capturedDashboardQueries),
        permanent: true,
      );

      await tester.pumpWidget(const SalesApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Quick order start'), findsOneWidget);
      expect(find.text('Sales Amount'), findsOneWidget);
      expect(capturedDashboardQueries.first['range'], equals('today'));

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(find.text('ORD-2026-001'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(capturedDashboardQueries.length, greaterThanOrEqualTo(2));
      expect(find.text('Summary'), findsOneWidget);
    },
  );
}
