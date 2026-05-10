import 'dart:convert';

import 'package:b2b_inventory_management/features/cart_orders/data/models/order_model.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_cache_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_repository.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/new_order_page_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/order_cart_step_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/order_confirm_step_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/order_customer_step_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/order_payment_step_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/order_products_step_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/pages/new_order_page.dart';
import 'package:b2b_inventory_management/features/customers/data/models/customer_model.dart';
import 'package:b2b_inventory_management/features/customers/data/repositories/customer_repository.dart';
import 'package:b2b_inventory_management/features/customers/presentation/controllers/customer_search_controller.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';
import 'package:b2b_inventory_management/features/products/presentation/controllers/product_list_controller.dart';
import 'package:b2b_inventory_management/core/offline/repositories/pending_actions_repository.dart';
import 'package:b2b_inventory_management/features/customers/data/repositories/customer_cache_repository.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_cache_repository.dart';
import 'package:b2b_inventory_management/core/offline/models/pending_action_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePendingActionsRepository extends Fake implements PendingActionsRepository {
  @override
  Future<int> insertAction(PendingAction action) async => 0;
}

class FakeCustomerCacheRepository extends Fake implements CustomerCacheRepository {
  @override
  Future<List<CustomerModel>> getCustomers({String? query}) async => [];
  @override
  Future<void> saveCustomers(List<CustomerModel> customers) async {}
}

class FakeProductCacheRepository extends Fake implements ProductCacheRepository {
  @override
  Future<List<ProductModel>> getProducts({String? query}) async => [];
  @override
  Future<void> saveProducts(List<ProductModel> products) async {}
}

class FakeOrderCacheRepository extends Fake implements OrderCacheRepository {
  @override
  Future<void> saveOrders(List<OrderModel> orders) async {}
  @override
  Future<void> saveOrder(OrderModel order) async {}
  @override
  Future<List<OrderModel>> getOrders({String? status}) async => [];
  @override
  Future<OrderModel?> getOrderById(int id) async => null;
  @override
  Future<void> deleteOrder(int id) async {}
}

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
      pendingActionsRepository: FakePendingActionsRepository(),
      customerCacheRepository: FakeCustomerCacheRepository(),
      orderCacheRepository: FakeOrderCacheRepository(),
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
      CustomerSearchController(
        customerRepository: createCustomerRepository(),
        customerCacheRepository: FakeCustomerCacheRepository(),
      ),
    );
    final productListController = Get.put(
      ProductListController(
        productRepository: productRepository,
        productCacheRepository: FakeProductCacheRepository(),
      ),
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
    Get.put(OrderPaymentStepController(cartController: cartController));
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
    expect(find.text('Discount'), findsNothing);
    expect(find.text('Continue to Payment'), findsOneWidget);

    cartController.setIntendedDeliveryAt(DateTime(2026, 4, 17, 15, 30));
    cartController.goToStep(CartController.paymentStep);
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsWidgets);
    expect(find.text('Discount'), findsWidgets);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Percent'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Payment amount'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Payment amount'), findsOneWidget);
    expect(find.text('Review Order'), findsOneWidget);
    expect(find.text('Save Draft'), findsNothing);
    expect(find.text('Confirm Order'), findsNothing);

    cartController.goToStep(CartController.confirmStep);
    await tester.pumpAndSettle();
    expect(find.text('Confirm order'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Payment summary'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Payment summary'), findsOneWidget);
  });
}
