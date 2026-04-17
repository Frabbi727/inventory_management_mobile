import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/constants/api_config.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/dashboard_range.dart';
import 'package:b2b_inventory_management/features/dashboard/data/repositories/salesman_dashboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'dashboard-token',
    });
  });

  test('fetchDashboard sends today by default contract', () async {
    final repository = SalesmanDashboardRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(
            request.url.toString(),
            equals('${ApiConfig.baseUrl}/api/dashboard/salesman?range=today'),
          );
          expect(
            request.headers['X-Authorization'],
            equals('Bearer dashboard-token'),
          );

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'filters': {
                  'range': 'today',
                  'start_date': '2026-04-17',
                  'end_date': '2026-04-17',
                },
                'summary': {
                  'sales_amount': 0,
                  'total_orders_count': 0,
                  'draft_orders_count': 0,
                  'confirmed_orders_count': 0,
                  'overdue_deliveries_count': 0,
                },
                'next_due_orders': const [],
                'recent_orders': const [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchDashboard(
      range: DashboardRange.today,
    );

    expect(response.success, isTrue);
    expect(response.data?.filters?.range, DashboardRange.today);
  });

  test('fetchDashboard sends custom dates only for custom range', () async {
    final repository = SalesmanDashboardRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['range'], equals('custom'));
          expect(
            request.url.queryParameters['start_date'],
            equals('2026-04-01'),
          );
          expect(request.url.queryParameters['end_date'], equals('2026-04-30'));

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'filters': {
                  'range': 'custom',
                  'start_date': '2026-04-01',
                  'end_date': '2026-04-30',
                },
                'summary': {
                  'sales_amount': 1250,
                  'total_orders_count': 4,
                  'draft_orders_count': 2,
                  'confirmed_orders_count': 2,
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
                'recent_orders': const [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );

    final response = await repository.fetchDashboard(
      range: DashboardRange.custom,
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 30),
    );

    expect(response.data?.summary?.salesAmount, equals(1250));
    expect(response.data?.nextDueOrders?.single.orderNo, equals('ORD-1001'));
    expect(
      response.data?.nextDueOrders?.single.customer?.name,
      equals('Rahim Store'),
    );
  });
}
