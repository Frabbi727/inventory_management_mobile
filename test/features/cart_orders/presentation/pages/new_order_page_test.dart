import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/cart_orders/data/repositories/order_repository.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/new_order_page_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_cart_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_confirm_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_customer_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/controllers/order_products_step_controller.dart';
import 'package:inventory_management_sales/features/cart_orders/presentation/pages/new_order_page.dart';
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
      'auth_token': 'widget-token',
    });
  });

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

  Future<void> pumpPage(WidgetTester tester) async {
    final productRepository = createProductRepository();
    final cartController = Get.put(
      CartController(
        orderRepository: createOrderRepository(),
        productRepository: productRepository,
      ),
    );
    final customerSearchController = Get.put(
      CustomerSearchController(customerRepository: createCustomerRepository()),
    );
    final productListController = Get.put(
      ProductListController(productRepository: productRepository),
    );

    Get.put(
      OrderCustomerStepController(
        cartController: cartController,
        customerSearchController: customerSearchController,
      ),
    );
    Get.put(NewOrderPageController(cartController: cartController));
    Get.put(
      OrderProductsStepController(
        cartController: cartController,
        productListController: productListController,
        productRepository: productRepository,
      ),
    );
    Get.put(OrderCartStepController(cartController: cartController));
    Get.put(OrderConfirmStepController(cartController: cartController));

    await tester.pumpWidget(const GetMaterialApp(home: NewOrderPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('new order shell swaps between separate step pages', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Available customers'), findsOneWidget);

    final cartController = Get.find<CartController>();
    cartController.setSelectedCustomer(
      const CustomerModel(id: 1, name: 'Rahman Store'),
    );
    cartController.goToStep(CartController.productsStep);
    await tester.pumpAndSettle();
    expect(find.text('Available products'), findsOneWidget);

    cartController.addProduct(
      const ProductModel(
        id: 7,
        name: 'Fresh Milk 500ml',
        sellingPrice: 52,
        currentStock: 5,
      ),
    );
    cartController.goToStep(CartController.cartStep);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Intended delivery'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Intended delivery'), findsOneWidget);
    expect(find.text('Continue to Confirm'), findsOneWidget);

    cartController.goToStep(CartController.confirmStep);
    await tester.pumpAndSettle();
    expect(find.text('Confirm order'), findsOneWidget);
  });
}
