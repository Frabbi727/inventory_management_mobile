import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:inventory_management_sales/features/customers/data/models/customer_model.dart';
import 'package:inventory_management_sales/features/products/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'cart-token',
    });
  });

  OrderRepository createRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return OrderRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      tokenStorage: TokenStorage(),
    );
  }

  const product = ProductModel(
    id: 7,
    name: 'Fresh Milk 500ml',
    sku: 'PRD-MILK-500',
    sellingPrice: 52,
    currentStock: 5,
  );

  test('adding the same product increments quantity and subtotal', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    expect(controller.addProduct(product), isTrue);
    expect(controller.addProduct(product), isTrue);

    expect(controller.items.single.quantity, equals(2));
    expect(controller.subtotal, equals(104));
  });

  test('estimated discount supports percent and amount', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    controller.addProduct(const ProductModel(id: 8, sellingPrice: 48));

    controller.setDiscountType('percent');
    controller.onDiscountValueChanged('10');
    expect(controller.estimatedDiscountAmount, equals(10));

    controller.setDiscountType('amount');
    controller.onDiscountValueChanged('20');
    expect(controller.estimatedDiscountAmount, equals(20));
    expect(controller.grandTotal, equals(80));
  });

  test('increment and decrement update items by product id', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    expect(controller.incrementQuantity(product.id), isTrue);
    expect(controller.items.single.quantity, equals(2));

    controller.decrementQuantity(product.id);
    expect(controller.items.single.quantity, equals(1));

    controller.decrementQuantity(product.id);
    expect(controller.items, isEmpty);
  });

  test(
    'submitOrder sends cart items and clears local state on success',
    () async {
      final controller = CartController(
        orderRepository: createRepository((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['customer_id'], equals(5));
          expect((body['items'] as List<dynamic>).length, equals(1));

          return http.Response(
            jsonEncode({
              'message': 'Order created successfully.',
              'data': {'id': 9, 'order_no': 'ORD-009', 'grand_total': 104},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      controller.addProduct(product);
      controller.setSelectedCustomer(
        const CustomerModel(id: 5, name: 'Rahman'),
      );

      final response = await controller.submitOrder();

      expect(response?.data?.orderNo, equals('ORD-009'));
      expect(controller.items, isEmpty);
      expect(controller.selectedCustomer.value, isNull);
    },
  );
}
