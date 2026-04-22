import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_repository.dart';
import 'package:b2b_inventory_management/features/invoice/presentation/controllers/invoice_controller.dart';
import 'package:b2b_inventory_management/features/invoice/presentation/pages/invoice_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'invoice-widget-token',
    });
  });

  testWidgets('orders page shows new search hint and filter sections', (
    tester,
  ) async {
    final controller = Get.put(
      InvoiceController(
        orderRepository: OrderRepository(
          apiClient: ApiClient(
            httpClient: MockClient(
              (request) async => http.Response(
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
        ),
      ),
    );
    controller.orders.clear();

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: InvoicePage())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Search by order no, customer name, or customer phone'),
      findsOneWidget,
    );

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Order date'), findsOneWidget);
    expect(find.text('Planned delivery date'), findsOneWidget);
    expect(find.text('Delivery state'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Due tomorrow'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Payment status'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Payment status'), findsOneWidget);
    expect(find.text('Not paid'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });
}
