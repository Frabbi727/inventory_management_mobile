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
import 'package:inventory_management_sales/features/products/data/models/product_variant_model.dart';
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

    controller.setDiscountType('percentage');
    controller.onDiscountValueChanged('10');
    expect(controller.estimatedDiscountAmount, equals(10));

    controller.setDiscountType('amount');
    controller.onDiscountValueChanged('20');
    expect(controller.estimatedDiscountAmount, equals(20));
    expect(controller.grandTotal, equals(80));
  });

  test('money values are normalized and formatted with two decimals', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(const ProductModel(id: 8, sellingPrice: 48.456));
    controller.setDiscountType('amount');
    controller.onDiscountValueChanged('12.345');

    expect(controller.subtotal, equals(48.46));
    expect(controller.discountValue.value, equals(12.35));
    expect(controller.grandTotal, equals(36.11));
    expect(controller.formatCurrency(controller.grandTotal), equals('৳36.11'));
    expect(controller.formatCurrency(80), equals('৳80.00'));
  });

  test(
    'percent discount is clamped and input text normalizes to two decimals',
    () {
      final controller = CartController(
        orderRepository: createRepository((request) async {
          return http.Response('{}', 200);
        }),
      );

      controller.addProduct(const ProductModel(id: 8, sellingPrice: 48.456));
      controller.setDiscountType('percentage');
      controller.onDiscountValueChanged('150.999');
      controller.discountValueController.text = '150.999';
      controller.normalizeDiscountInputText();

      expect(controller.appliedDiscountValue, equals(100));
      expect(controller.discountValueController.text, equals('100.00'));
      expect(controller.estimatedDiscountAmount, equals(48.46));
      expect(controller.grandTotal, equals(0));
    },
  );

  test('increment and decrement update items by product id', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    expect(controller.incrementQuantity('${product.id}:base'), isTrue);
    expect(controller.items.single.quantity, equals(2));

    controller.decrementQuantity('${product.id}:base');
    expect(controller.items.single.quantity, equals(1));

    controller.decrementQuantity('${product.id}:base');
    expect(controller.items, isEmpty);
    expect(controller.currentStep.value, CartController.customerStep);
  });

  test('variant lines merge by product and variant id', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    const variantProduct = ProductModel(
      id: 9,
      name: 'Aquafina Water',
      hasVariants: true,
    );
    const small = ProductVariantModel(
      id: 101,
      combinationKey: 'size-500ml',
      combinationLabel: '500ml',
      sellingPrice: 40,
      currentStock: 10,
    );
    const large = ProductVariantModel(
      id: 102,
      combinationKey: 'size-1-liter',
      combinationLabel: '1 Liter',
      sellingPrice: 50,
      currentStock: 8,
    );

    expect(controller.addProduct(variantProduct, variant: small), isTrue);
    expect(controller.addProduct(variantProduct, variant: small), isTrue);
    expect(controller.addProduct(variantProduct, variant: large), isTrue);

    expect(controller.items.length, 2);
    expect(controller.items.first.quantity, 2);
    expect(controller.items.first.unitPrice, 40);
    expect(controller.items.last.variantLabel, '1 Liter');
  });

  test(
    'submitOrder sends cart items and clears local state on success',
    () async {
      final controller = CartController(
        orderRepository: createRepository((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['customer_id'], equals(5));
          expect((body['items'] as List<dynamic>).length, equals(1));
          expect(body['items'][0]['product_variant_id'], 101);

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

      controller.addProduct(
        const ProductModel(id: 7, name: 'Aquafina Water', hasVariants: true),
        variant: const ProductVariantModel(
          id: 101,
          combinationKey: 'size-500ml',
          combinationLabel: '500ml',
          sellingPrice: 40,
          currentStock: 5,
        ),
      );
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
