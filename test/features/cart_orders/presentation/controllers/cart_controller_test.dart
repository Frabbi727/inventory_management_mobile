import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_repository.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:b2b_inventory_management/features/customers/data/models/customer_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_variant_model.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';
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

  ProductRepository createProductRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ProductRepository(
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
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    expect(controller.addProduct(product), isTrue);
    expect(controller.addProduct(product), isTrue);

    expect(controller.items.single.quantity, equals(2));
    expect(controller.subtotal, equals(104));
  });

  test(
    'addProduct supports initial quantity and setLineQuantity updates it',
    () {
      final controller = CartController(
        orderRepository: createRepository((request) async {
          return http.Response('{}', 200);
        }),
        productRepository: createProductRepository((request) async {
          return http.Response('{}', 200);
        }),
      );

      expect(controller.addProduct(product, quantity: 12), isTrue);
      expect(controller.items.single.quantity, equals(12));
      expect(
        controller.setLineQuantity(controller.items.single.lineKey, 25),
        isTrue,
      );
      expect(controller.items.single.quantity, equals(25));
      expect(controller.totalUnits, equals(25));
    },
  );

  test('estimated discount supports percent and amount', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    controller.addProduct(const ProductModel(id: 8, sellingPrice: 48));
    controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));

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
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(const ProductModel(id: 8, sellingPrice: 48.456));
    controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));
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
        productRepository: createProductRepository((request) async {
          return http.Response('{}', 200);
        }),
      );

      controller.addProduct(const ProductModel(id: 8, sellingPrice: 48.456));
      controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));
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
      productRepository: createProductRepository((request) async {
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

  test('setLineQuantity removes line at zero and keeps overstock warnings', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));
    expect(controller.setLineQuantity('${product.id}:base', 8), isTrue);
    expect(controller.items.single.quantity, equals(8));
    expect(controller.items.single.exceedsAvailableStock, isTrue);
    expect(controller.canConfirm, isFalse);

    expect(controller.setLineQuantity('${product.id}:base', 0), isTrue);
    expect(controller.items, isEmpty);
  });

  test('variant lines merge by product and variant id', () {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
      productRepository: createProductRepository((request) async {
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
      var requestCount = 0;
      final controller = CartController(
        orderRepository: createRepository((request) async {
          requestCount += 1;

          if (requestCount == 1) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['customer_id'], equals(5));
            expect((body['items'] as List<dynamic>).length, equals(1));
            expect(body['items'][0]['product_variant_id'], 101);
            expect(body['payment_amount'], 40);
            expect(
              body['intended_delivery_at'],
              contains('2026-04-17T15:30:00'),
            );

            return http.Response(
              jsonEncode({
                'message': 'Draft saved successfully.',
                'data': {
                  'id': 9,
                  'order_no': 'ORD-009',
                  'grand_total': 104,
                  'payment_amount': 40,
                  'payment_status': 'paid',
                  'due_amount': 0,
                  'status': 'draft',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          expect(request.method, equals('POST'));
          expect(request.url.path, endsWith('/api/orders/9/confirm'));

          return http.Response(
            jsonEncode({
              'message': 'Order confirmed successfully.',
              'data': {
                'id': 9,
                'order_no': 'ORD-009',
                'grand_total': 104,
                'payment_amount': 104,
                'payment_status': 'paid',
                'due_amount': 0,
                'status': 'confirmed',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        productRepository: createProductRepository((request) async {
          return http.Response('{}', 200);
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
      controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));
      controller.onPaymentAmountChanged('40');

      final response = await controller.submitOrder();

      expect(response?.data?.orderNo, equals('ORD-009'));
      expect(response?.data?.status, equals('confirmed'));
      expect(controller.items, isEmpty);
      expect(controller.selectedCustomer.value, isNull);
    },
  );

  test('draft save requires intended delivery timestamp', () async {
    final controller = CartController(
      orderRepository: createRepository((request) async {
        return http.Response('{}', 200);
      }),
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    controller.setSelectedCustomer(const CustomerModel(id: 5, name: 'Rahman'));

    final response = await controller.saveDraft();

    expect(response, isNull);
    expect(
      controller.errorMessage.value,
      equals(
        'Select the intended delivery date and time before saving the draft.',
      ),
    );
    expect(controller.canSaveDraft, isFalse);
  });

  test('repeated draft payment sends cumulative payment amount', () async {
    var requestCount = 0;
    final controller = CartController(
      orderRepository: createRepository((request) async {
        requestCount += 1;
        final body = jsonDecode(request.body) as Map<String, dynamic>;

        if (requestCount == 1) {
          expect(body['payment_amount'], 20);
          return http.Response(
            jsonEncode({
              'message': 'Draft saved successfully.',
              'data': {
                'id': 11,
                'order_no': 'ORD-011',
                'grand_total': 52,
                'payment_amount': 20,
                'payment_status': 'partial',
                'due_amount': 32,
                'status': 'draft',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        expect(body['payment_amount'], 52);
        return http.Response(
          jsonEncode({
            'message': 'Draft saved successfully.',
            'data': {
              'id': 11,
              'order_no': 'ORD-011',
              'grand_total': 52,
              'payment_amount': 52,
              'payment_status': 'paid',
              'due_amount': 0,
              'status': 'draft',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      productRepository: createProductRepository((request) async {
        return http.Response('{}', 200);
      }),
    );

    controller.addProduct(product);
    controller.setSelectedCustomer(const CustomerModel(id: 5, name: 'Rahman'));
    controller.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));

    controller.onPaymentAmountChanged('20');
    final firstResponse = await controller.saveDraft();
    expect(firstResponse?.data?.paymentStatus, 'partial');
    expect(controller.savedPaymentAmount, 20);
    expect(controller.enteredPaymentAmount, 0);
    expect(controller.canConfirm, isFalse);

    controller.onPaymentAmountChanged('32');
    final secondResponse = await controller.saveDraft();
    expect(secondResponse?.data?.paymentStatus, 'paid');
    expect(controller.savedPaymentAmount, 52);
    expect(controller.displayDueAmount, 0);
    expect(controller.canConfirm, isTrue);
  });
}
