import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_cart_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_confirm_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_customer_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_products_step_controller.dart';
import 'package:inventory_management_sales/features/customers/data/models/customer_model.dart';
import 'package:inventory_management_sales/features/customers/data/repositories/customer_repository.dart';
import 'package:inventory_management_sales/features/customers/presentation/controllers/customer_search_controller.dart';
import 'package:inventory_management_sales/features/products/data/models/product_model.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:inventory_management_sales/features/products/presentation/controllers/product_list_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'step-token',
    });
  });

  OrderRepository createOrderRepository() {
    return OrderRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (request) async => http.Response(jsonEncode({'data': []}), 200),
        ),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  ProductRepository createProductRepository() {
    return ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/categories')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 1, 'name': 'Dairy'},
                ],
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 7,
                  'name': 'Fresh Milk 500ml',
                  'sku': 'PRD-MILK-500',
                  'selling_price': 52,
                  'current_stock': 5,
                },
              ],
              'links': {'first': '', 'last': '', 'prev': null, 'next': null},
              'meta': {'current_page': 1, 'last_page': 1, 'links': const []},
            }),
            200,
          );
        }),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  CustomerRepository createCustomerRepository() {
    return CustomerRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'name': 'Rahman Store',
                  'phone': '+8801710001001',
                  'address': '12 Lake Circus, Dhaka',
                  'area': 'Dhanmondi',
                },
              ],
              'links': {'first': '', 'last': '', 'prev': null, 'next': null},
              'meta': {'current_page': 1, 'last_page': 1, 'links': const []},
            }),
            200,
          ),
        ),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  CartController createCartController() {
    return CartController(
      orderRepository: createOrderRepository(),
      productRepository: createProductRepository(),
    );
  }

  test(
    'customer step controller selects customer through shared cart state',
    () {
      final cartController = Get.put(createCartController());
      final searchController = Get.put(
        CustomerSearchController(
          customerRepository: createCustomerRepository(),
        ),
      );

      final controller = Get.put(
        OrderCustomerStepController(
          cartController: cartController,
          customerSearchController: searchController,
        ),
      );

      const customer = CustomerModel(id: 5, name: 'Mina Traders');

      controller.selectCustomer(customer);

      expect(cartController.selectedCustomer.value?.id, 5);
    },
  );

  test('products step controller adds product and updates existing line', () {
    final cartController = Get.put(createCartController());
    final productListController = Get.put(
      ProductListController(productRepository: createProductRepository()),
    );

    final controller = Get.put(
      OrderProductsStepController(
        cartController: cartController,
        productListController: productListController,
        productRepository: createProductRepository(),
      ),
    );

    const product = ProductModel(
      id: 7,
      name: 'Fresh Milk 500ml',
      sellingPrice: 52,
      currentStock: 5,
    );

    controller.updateProductQuantity(product, 2);
    controller.updateProductQuantity(product, 4);

    expect(cartController.items.single.quantity, 4);
  });

  test('cart step controller updates shared line quantity and removal', () {
    final cartController = Get.put(createCartController());
    cartController.addProduct(
      const ProductModel(
        id: 7,
        name: 'Fresh Milk 500ml',
        sellingPrice: 52,
        currentStock: 5,
      ),
      quantity: 2,
    );

    final controller = Get.put(
      OrderCartStepController(cartController: cartController),
    );

    controller.updateQuantity(cartController.items.single.lineKey, 3);
    expect(cartController.items.single.quantity, 3);

    controller.removeItem(cartController.items.single.lineKey);
    expect(cartController.items, isEmpty);
  });

  test(
    'cart step controller exposes intended delivery through shared state',
    () {
      final cartController = Get.put(createCartController());
      final controller = Get.put(
        OrderCartStepController(cartController: cartController),
      );

      cartController.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));

      expect(
        controller.cartController.formatIntendedDeliveryDisplay(),
        contains('2026'),
      );
    },
  );

  test(
    'confirm step controller keeps access to shared cart workflow state',
    () {
      final cartController = Get.put(createCartController());
      cartController.setSelectedCustomer(
        const CustomerModel(id: 1, name: 'Rahman'),
      );
      cartController.addProduct(
        const ProductModel(
          id: 7,
          name: 'Milk',
          sellingPrice: 52,
          currentStock: 5,
        ),
      );
      cartController.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));

      final controller = Get.put(
        OrderConfirmStepController(cartController: cartController),
      );

      expect(controller.cartController.canSaveDraft, isTrue);
      expect(controller.cartController.canConfirm, isTrue);
    },
  );
}
