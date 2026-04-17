import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:inventory_management_sales/features/invoice/presentation/controllers/invoice_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'invoice-token',
    });
  });

  OrderRepository createRepository(List<Map<String, String>> recordedQueries) {
    return OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          recordedQueries.add(request.url.queryParameters);
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
  }

  testWidgets('search below 3 chars does not trigger backend query', (
    tester,
  ) async {
    final recordedQueries = <Map<String, String>>[];
    final controller = InvoiceController(
      orderRepository: createRepository(recordedQueries),
    );

    controller.onSearchChanged('ab');
    await tester.pump(const Duration(milliseconds: 500));

    expect(recordedQueries, isEmpty);
  });

  testWidgets(
    'search with 3 chars triggers backend query and preserves filters',
    (tester) async {
      final recordedQueries = <Map<String, String>>[];
      final controller = InvoiceController(
        orderRepository: createRepository(recordedQueries),
      );

      await controller.applyFilters(
        orderDateRange: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        intendedDeliveryDateRange: DateTimeRange(
          start: DateTime(2026, 4, 10),
          end: DateTime(2026, 4, 20),
        ),
        deliveryState: 'due_today',
      );
      recordedQueries.clear();

      controller.onSearchChanged('rah');
      await tester.pump(const Duration(milliseconds: 500));

      expect(recordedQueries, hasLength(1));
      expect(recordedQueries.single['q'], equals('rah'));
      expect(recordedQueries.single['status'], equals('draft'));
      expect(recordedQueries.single['start_date'], equals('2026-04-01'));
      expect(recordedQueries.single['end_date'], equals('2026-04-30'));
      expect(
        recordedQueries.single['intended_delivery_start'],
        equals('2026-04-10'),
      );
      expect(
        recordedQueries.single['intended_delivery_end'],
        equals('2026-04-20'),
      );
      expect(recordedQueries.single['delivery_state'], equals('due_today'));
    },
  );

  testWidgets('changing tabs preserves active due and date filters', (
    tester,
  ) async {
    final recordedQueries = <Map<String, String>>[];
    final controller = InvoiceController(
      orderRepository: createRepository(recordedQueries),
    );

    await controller.applyFilters(
      orderDateRange: DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 30),
      ),
      intendedDeliveryDateRange: DateTimeRange(
        start: DateTime(2026, 4, 10),
        end: DateTime(2026, 4, 20),
      ),
      deliveryState: 'overdue',
    );
    recordedQueries.clear();

    await controller.changeStatusTab('confirmed');

    expect(recordedQueries, hasLength(1));
    expect(recordedQueries.single['status'], equals('confirmed'));
    expect(recordedQueries.single['start_date'], equals('2026-04-01'));
    expect(
      recordedQueries.single['intended_delivery_start'],
      equals('2026-04-10'),
    );
    expect(recordedQueries.single['delivery_state'], equals('overdue'));
  });

  testWidgets(
    'clearing search reloads orders without q while keeping filters',
    (tester) async {
      final recordedQueries = <Map<String, String>>[];
      final controller = InvoiceController(
        orderRepository: createRepository(recordedQueries),
      );

      await controller.applyFilters(
        orderDateRange: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        intendedDeliveryDateRange: DateTimeRange(
          start: DateTime(2026, 4, 10),
          end: DateTime(2026, 4, 20),
        ),
        deliveryState: 'due_tomorrow',
      );
      recordedQueries.clear();

      controller.onSearchChanged('rah');
      await tester.pump(const Duration(milliseconds: 500));
      recordedQueries.clear();

      controller.onSearchChanged('');
      await tester.pump();

      expect(recordedQueries, hasLength(1));
      expect(recordedQueries.single.containsKey('q'), isFalse);
      expect(recordedQueries.single['status'], equals('draft'));
      expect(recordedQueries.single['start_date'], equals('2026-04-01'));
      expect(
        recordedQueries.single['intended_delivery_start'],
        equals('2026-04-10'),
      );
      expect(recordedQueries.single['delivery_state'], equals('due_tomorrow'));
    },
  );

  testWidgets('clearAllCriteria resets supported filters and search state', (
    tester,
  ) async {
    final recordedQueries = <Map<String, String>>[];
    final controller = InvoiceController(
      orderRepository: createRepository(recordedQueries),
    );

    controller.searchTextController.text = 'rah';
    controller.searchQuery.value = 'rah';
    await controller.applyFilters(
      orderDateRange: DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 30),
      ),
      intendedDeliveryDateRange: DateTimeRange(
        start: DateTime(2026, 4, 10),
        end: DateTime(2026, 4, 20),
      ),
      deliveryState: 'overdue',
    );
    recordedQueries.clear();

    await controller.clearAllCriteria();
    await tester.pump();

    expect(controller.searchQuery.value, isEmpty);
    expect(controller.searchTextController.text, isEmpty);
    expect(controller.hasActiveFilters, isFalse);
    expect(controller.activeFilterCount, equals(0));
    expect(controller.selectedOrderDateRange, isNull);
    expect(controller.selectedIntendedDeliveryDateRange, isNull);
    expect(controller.deliveryState.value, isNull);
    expect(recordedQueries, hasLength(1));
    expect(recordedQueries.single.containsKey('q'), isFalse);
    expect(recordedQueries.single.containsKey('start_date'), isFalse);
    expect(
      recordedQueries.single.containsKey('intended_delivery_start'),
      isFalse,
    );
    expect(recordedQueries.single.containsKey('delivery_state'), isFalse);
    expect(recordedQueries.single['status'], equals('draft'));
  });
}
