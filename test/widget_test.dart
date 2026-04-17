import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/app.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/core/storage/user_storage.dart';
import 'package:b2b_inventory_management/features/auth/data/models/user_model.dart';
import 'package:b2b_inventory_management/features/auth/data/repositories/auth_repository.dart';
import 'package:b2b_inventory_management/features/cart_orders/data/repositories/order_repository.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/controllers/cart_controller.dart';
import 'package:b2b_inventory_management/features/cart_orders/presentation/widgets/order_flow_widgets.dart';
import 'package:b2b_inventory_management/features/customers/data/models/customer_model.dart';
import 'package:b2b_inventory_management/features/customers/data/repositories/customer_repository.dart';
import 'package:b2b_inventory_management/features/dashboard/data/repositories/salesman_dashboard_repository.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  AuthRepository createRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return AuthRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
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

  CustomerRepository createCustomerRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return CustomerRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      tokenStorage: TokenStorage(),
    );
  }

  OrderRepository createOrderRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return OrderRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      tokenStorage: TokenStorage(),
    );
  }

  SalesmanDashboardRepository createDashboardRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return SalesmanDashboardRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      tokenStorage: TokenStorage(),
    );
  }

  Map<String, dynamic> productListPayload({
    required List<Map<String, dynamic>> products,
    int currentPage = 1,
    int lastPage = 1,
    String? nextUrl,
  }) {
    return {
      'data': products,
      'links': {
        'first': 'https://ordermanage.b2bhaat.com/api/products?page=1',
        'last': 'https://ordermanage.b2bhaat.com/api/products?page=$lastPage',
        'prev': currentPage > 1
            ? 'https://ordermanage.b2bhaat.com/api/products?page=${currentPage - 1}'
            : null,
        'next': nextUrl,
      },
      'meta': {
        'current_page': currentPage,
        'from': 1,
        'last_page': lastPage,
        'links': const [],
        'path': 'https://ordermanage.b2bhaat.com/api/products',
        'per_page': 15,
        'to': products.length,
        'total': products.length,
      },
    };
  }

  const sampleProducts = [
    {
      'id': 2,
      'name': 'Fresh Milk 500ml',
      'sku': 'PRD-MILK-500',
      'selling_price': 52,
      'current_stock': 18,
      'category': {'id': 2, 'name': 'Dairy'},
      'unit': {'id': 1, 'name': 'Piece', 'short_name': 'pc'},
    },
    {
      'id': 3,
      'name': 'Premium Biscuit Pack',
      'sku': 'PRD-BISC-220',
      'selling_price': 35,
      'current_stock': 6,
      'category': {'id': 3, 'name': 'Snacks'},
      'unit': {'id': 1, 'name': 'Piece', 'short_name': 'pc'},
    },
  ];

  const sampleCategories = [
    {'id': 2, 'name': 'Dairy'},
    {'id': 3, 'name': 'Snacks'},
  ];

  const sampleSubcategories = [
    {'id': 21, 'name': 'Milk', 'category_id': 2},
    {'id': 22, 'name': 'Yogurt', 'category_id': 2},
  ];

  const sampleVariantProduct = {
    'id': 9,
    'name': 'Aquafina Water',
    'sku': 'PRD-WATER-001',
    'has_variants': true,
    'current_stock': 18,
    'category': {'id': 2, 'name': 'Dairy'},
    'unit': {'id': 1, 'name': 'Piece', 'short_name': 'pc'},
  };

  const sampleVariantDetails = {
    'data': {
      'id': 9,
      'name': 'Aquafina Water',
      'sku': 'PRD-WATER-001',
      'has_variants': true,
      'current_stock': 18,
      'category': {'id': 2, 'name': 'Dairy'},
      'unit': {'id': 1, 'name': 'Piece', 'short_name': 'pc'},
      'variants': [
        {
          'id': 101,
          'combination_label': '500ml',
          'combination_key': 'size-500ml',
          'selling_price': 40,
          'current_stock': 10,
        },
        {
          'id': 102,
          'combination_label': '1 Liter',
          'combination_key': 'size-1-liter',
          'selling_price': 60,
          'current_stock': 0,
        },
      ],
    },
  };

  const sampleCustomers = [
    {
      'id': 1,
      'name': 'Rahman Store',
      'phone': '+8801710001001',
      'address': '12 Lake Circus, Dhaka',
      'area': 'Dhanmondi',
      'created_by': {'id': 2, 'name': 'Sales Demo'},
    },
    {
      'id': 2,
      'name': 'Mina Traders',
      'phone': '+8801710001002',
      'address': 'Mirpur DOHS, Dhaka',
      'area': 'Mirpur',
      'created_by': {'id': 2, 'name': 'Sales Demo'},
    },
  ];

  Map<String, dynamic> customerListPayload({
    required List<Map<String, dynamic>> customers,
    int currentPage = 1,
    int lastPage = 1,
    String? nextUrl,
  }) {
    return {
      'data': customers,
      'links': {
        'first': 'https://ordermanage.b2bhaat.com/api/customers?page=1',
        'last': 'https://ordermanage.b2bhaat.com/api/customers?page=$lastPage',
        'prev': currentPage > 1
            ? 'https://ordermanage.b2bhaat.com/api/customers?page=${currentPage - 1}'
            : null,
        'next': nextUrl,
      },
      'meta': {
        'current_page': currentPage,
        'from': 1,
        'last_page': lastPage,
        'links': const [],
        'path': 'https://ordermanage.b2bhaat.com/api/customers',
        'per_page': 15,
        'to': customers.length,
        'total': customers.length,
      },
    };
  }

  Map<String, dynamic> orderCreatePayload({
    String message = 'Order created successfully.',
    String status = 'confirmed',
  }) {
    return {
      'message': message,
      'data': {
        'id': 99,
        'order_no': 'ORD-ABC12345',
        'order_date': '2026-04-09',
        'subtotal': 104,
        'discount_type': 'amount',
        'discount_value': 4,
        'discount_amount': 4,
        'grand_total': 100,
        'status': status,
        'note': 'Deliver quickly',
        'customer': {
          'id': 1,
          'name': 'Rahman Store',
          'phone': '+8801710001001',
        },
        'salesman': {'id': 2, 'name': 'Sales Demo'},
        'items': [
          {
            'id': 1,
            'product_id': 2,
            'product_name': 'Fresh Milk 500ml',
            'quantity': 2,
            'unit_price': 52,
            'line_total': 104,
          },
        ],
      },
    };
  }

  Map<String, dynamic> orderListPayload() {
    return {
      'data': [
        {
          'id': 11,
          'order_no': 'ORD-2026-001',
          'order_date': '2026-04-09T00:00:00.000000Z',
          'subtotal': 139,
          'discount_type': null,
          'discount_value': null,
          'discount_amount': 0,
          'grand_total': 139,
          'status': 'confirmed',
          'note': null,
          'customer': {
            'id': 1,
            'name': 'Rahman Store',
            'phone': '+8801710001001',
          },
          'salesman': {'id': 2, 'name': 'Sales Demo'},
          'items': [
            {
              'id': 1,
              'product_id': 2,
              'product_name': 'Fresh Milk 500ml',
              'quantity': 2,
              'unit_price': 52,
              'line_total': 104,
            },
          ],
          'created_at': '2026-04-09T10:00:00.000000Z',
          'updated_at': '2026-04-09T10:00:00.000000Z',
        },
      ],
      'links': {'next': null},
      'meta': {'current_page': 1, 'last_page': 1},
    };
  }

  Map<String, dynamic> orderDetailsPayload() {
    return {
      'data': {
        'id': 11,
        'order_no': 'ORD-2026-001',
        'order_date': '2026-04-09',
        'subtotal': 139,
        'discount_type': null,
        'discount_value': null,
        'discount_amount': 0,
        'grand_total': 139,
        'status': 'confirmed',
        'note': 'Deliver before noon',
        'customer': {
          'id': 1,
          'name': 'Rahman Store',
          'phone': '+8801710001001',
        },
        'salesman': {'id': 2, 'name': 'Sales Demo'},
        'items': [
          {
            'id': 1,
            'product_id': 2,
            'product_name': 'Fresh Milk 500ml',
            'quantity': 2,
            'unit_price': 52,
            'line_total': 104,
          },
        ],
      },
    };
  }

  void registerDefaultOrderRepository() {
    Get.put<OrderRepository>(
      createOrderRepository((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/orders/11')) {
          return http.Response(
            jsonEncode(orderDetailsPayload()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'GET' && request.url.path.endsWith('/orders')) {
          return http.Response(
            jsonEncode(orderListPayload()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode(orderCreatePayload()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    if (!Get.isRegistered<SalesmanDashboardRepository>()) {
      Get.put<SalesmanDashboardRepository>(
        createDashboardRepository((request) async {
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
        permanent: true,
      );
    }

    if (!Get.isRegistered<SalesmanDashboardRepository>()) {
      Get.put<SalesmanDashboardRepository>(
        createDashboardRepository((request) async {
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
        permanent: true,
      );
    }
  }

  testWidgets('app boots into splash screen first', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const SalesApp());

    expect(find.text('Inventory Sales'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('splash redirects to login when there is no token', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Salesman Sign In'), findsOneWidget);
    expect(find.text('Salesman Sign In'), findsOneWidget);
  });

  testWidgets('splash verifies token with profile API before routing home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'sample-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
        expect(
          request.headers['X-Authorization'],
          equals('Bearer sample-token'),
        );
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
      }),
      permanent: true,
    );
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<OrderRepository>(
      createOrderRepository((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/orders/11')) {
          return http.Response(
            jsonEncode(orderDetailsPayload()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode(orderListPayload()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    if (!Get.isRegistered<SalesmanDashboardRepository>()) {
      Get.put<SalesmanDashboardRepository>(
        createDashboardRepository((request) async {
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
        permanent: true,
      );
    }

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Start New Order'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('invalid stored token clears session and returns to login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'bad-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    final tokenStorage = TokenStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Salesman Sign In'), findsOneWidget);
    expect(await tokenStorage.getToken(), isNull);
  });

  testWidgets('successful login stores session and routes to home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    Get.put<AuthRepository>(
      createRepository((request) async {
        if (request.url.path.endsWith('/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['login'], equals('salesman@example.com'));
          expect(body['password'], equals('secret'));
          expect(body['device_name'], equals('flutter-mobile'));

          return http.Response(
            jsonEncode({
              'message': 'Login successful.',
              'data': {
                'token': 'login-token',
                'token_type': 'Bearer',
                'user': {
                  'id': 2,
                  'name': 'Sales Demo',
                  'email': 'salesman@example.com',
                  'phone': '+8801700000002',
                  'role': {'id': 2, 'name': 'Salesman', 'slug': 'salesman'},
                },
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    final tokenStorage = TokenStorage();
    final userStorage = UserStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'salesman@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('New Order'), findsOneWidget);
    expect(await tokenStorage.getToken(), equals('login-token'));
    expect((await userStorage.getUser())?.name, equals('Sales Demo'));
  });

  testWidgets('failed login shows backend error and stays on login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    Get.put<AuthRepository>(
      createRepository((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Invalid credentials.',
            'errors': {
              'login': ['The provided credentials are incorrect.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'bad-user');
    await tester.enterText(find.byType(TextFormField).last, 'bad-pass');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials.'), findsOneWidget);
    expect(find.text('Products'), findsNothing);
  });

  testWidgets('bottom tabs switch between main salesman workflows', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'shell-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('ORD-2026-001'), findsOneWidget);

    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();
    expect(find.text('Rahman Store'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Sales Demo'), findsOneWidget);
  });

  testWidgets('logout clears session and returns to login', (
    WidgetTester tester,
  ) async {
    final storedUser = UserModel(
      id: 2,
      name: 'Sales Demo',
      email: 'salesman@example.com',
      phone: '+8801700000002',
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'logout-token',
      'session_user': jsonEncode(storedUser.toJson()),
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            jsonEncode({'data': storedUser.toJson()}),
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    final tokenStorage = TokenStorage();
    final userStorage = UserStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pump();
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(find.text('Salesman Sign In'), findsOneWidget);
    expect(await tokenStorage.getToken(), isNull);
    expect(await userStorage.getUser(), isNull);
  });

  testWidgets('customer selection works inside the guided new order flow', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'customer-shell-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();

    expect(find.text('Subtotal'), findsNothing);
    expect(find.text('Total'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'rah');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Rahman Store'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Select').first);
    await tester.pump();

    final cartController = Get.find<CartController>();
    expect(cartController.selectedCustomer.value?.name, equals('Rahman Store'));
    expect(
      cartController.selectedCustomer.value?.phone,
      equals('+8801710001001'),
    );
    expect(find.widgetWithText(FilledButton, 'Selected'), findsOneWidget);
  });

  testWidgets('products can be added and submitted from new order flow', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'order-shell-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<OrderRepository>(
      createOrderRepository((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/orders/11')) {
          return http.Response(
            jsonEncode(orderDetailsPayload()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'GET' && request.url.path.endsWith('/orders')) {
          return http.Response(
            jsonEncode(orderListPayload()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'POST' &&
            request.url.path.endsWith('/orders/99/confirm')) {
          return http.Response(
            jsonEncode(
              orderCreatePayload(
                message: 'Order confirmed successfully.',
                status: 'confirmed',
              ),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        expect(request.url.path.endsWith('/orders'), isTrue);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['customer_id'], equals(1));
        expect((body['items'] as List<dynamic>).first['product_id'], equals(2));
        expect((body['items'] as List<dynamic>).first['quantity'], equals(2));

        return http.Response(
          jsonEncode(
            orderCreatePayload(
              message: 'Draft saved successfully.',
              status: 'draft',
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final cartController = Get.find<CartController>();
    final firstProduct = ProductModel.fromJson(sampleProducts.first);
    cartController.addProduct(firstProduct);
    cartController.addProduct(firstProduct);
    cartController.setSelectedCustomer(
      const CustomerModel(id: 1, name: 'Rahman Store', phone: '+8801710001001'),
    );
    cartController.setDiscountType('amount');
    cartController.onDiscountValueChanged('4');
    cartController.noteController.text = 'Deliver quickly';

    await cartController.submitOrder();
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('ORD-ABC12345'), findsOneWidget);
    expect(find.text('View Orders'), findsOneWidget);
  });

  testWidgets(
    'products step shows category and subcategory searchable filters',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'product-filter-token',
      });

      Get.put<AuthRepository>(
        createRepository((request) async {
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
      Get.put<ProductRepository>(
        createProductRepository((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/categories')) {
            return http.Response(
              jsonEncode({'data': sampleCategories}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/subcategories')) {
            expect(request.url.queryParameters['category_id'], equals('2'));
            return http.Response(
              jsonEncode({'data': sampleSubcategories}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode(productListPayload(products: sampleProducts)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      Get.put<CustomerRepository>(
        createCustomerRepository((request) async {
          return http.Response(
            jsonEncode(customerListPayload(customers: sampleCustomers)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      registerDefaultOrderRepository();

      await tester.pumpWidget(const SalesApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Select').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Products'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Search by product name or SKU'), findsOneWidget);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Products'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Subcategory'), findsOneWidget);
      expect(find.text('Select a category first'), findsOneWidget);

      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dairy').last);
      await tester.pumpAndSettle();

      expect(find.text('Dairy'), findsWidgets);
      expect(find.text('All subcategories'), findsOneWidget);
    },
  );

  testWidgets(
    'guided new order flow syncs product add with cart quantity controls',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'cart-sync-token',
      });

      Get.put<AuthRepository>(
        createRepository((request) async {
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
      Get.put<ProductRepository>(
        createProductRepository((request) async {
          return http.Response(
            jsonEncode(productListPayload(products: sampleProducts)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      Get.put<CustomerRepository>(
        createCustomerRepository((request) async {
          return http.Response(
            jsonEncode(customerListPayload(customers: sampleCustomers)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      registerDefaultOrderRepository();

      await tester.pumpWidget(const SalesApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Order'));
      await tester.pumpAndSettle();
      expect(find.text('Customer'), findsWidgets);

      final cartController = Get.find<CartController>();
      cartController.setSelectedCustomer(
        const CustomerModel(id: 1, name: 'Rahman Store'),
      );
      cartController.goToStep(CartController.productsStep);
      await tester.pumpAndSettle();

      expect(find.text('Fresh Milk 500ml'), findsWidgets);
      cartController.addProduct(ProductModel.fromJson(sampleProducts.first));
      await tester.pumpAndSettle();

      expect(cartController.items.single.productId, equals(2));
      expect(cartController.items.single.quantity, equals(1));

      cartController.goToStep(CartController.cartStep);
      await tester.pumpAndSettle();

      expect(find.text('Cart'), findsWidgets);
      expect(find.text('Fresh Milk 500ml'), findsWidgets);

      cartController.incrementQuantity(cartController.items.single.lineKey);
      await tester.pump();
      expect(cartController.items.single.quantity, equals(2));

      cartController.decrementQuantity(cartController.items.single.lineKey);
      await tester.pump();
      expect(cartController.items.single.quantity, equals(1));
    },
  );

  testWidgets(
    'variant products open quick picker and allow typed quantity entry',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'variant-picker-token',
      });

      Get.put<AuthRepository>(
        createRepository((request) async {
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
      Get.put<ProductRepository>(
        createProductRepository((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/products/9')) {
            return http.Response(
              jsonEncode(sampleVariantDetails),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode(productListPayload(products: [sampleVariantProduct])),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      Get.put<CustomerRepository>(
        createCustomerRepository((request) async {
          return http.Response(
            jsonEncode(customerListPayload(customers: sampleCustomers)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        permanent: true,
      );
      registerDefaultOrderRepository();

      await tester.pumpWidget(const SalesApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Order'));
      await tester.pumpAndSettle();

      final cartController = Get.find<CartController>();
      cartController.setSelectedCustomer(
        const CustomerModel(id: 1, name: 'Rahman Store'),
      );
      cartController.goToStep(CartController.productsStep);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Choose a variant and type the quantity you want to add.'),
        findsOneWidget,
      );
      expect(find.text('500ml'), findsOneWidget);
      expect(find.text('1 Liter'), findsOneWidget);

      final quantityField = find
          .descendant(
            of: find.byType(QuantityStepper).first,
            matching: find.byType(TextField),
          )
          .first;

      await tester.enterText(quantityField, '12');
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(cartController.items.single.productVariantId, equals(101));
      expect(cartController.items.single.quantity, equals(12));
    },
  );

  testWidgets('cart quantity field accepts typed values for large orders', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'cart-input-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();

    final cartController = Get.find<CartController>();
    cartController.addProduct(ProductModel.fromJson(sampleProducts.first));
    cartController.setSelectedCustomer(
      const CustomerModel(id: 1, name: 'Rahman Store'),
    );
    cartController.goToStep(CartController.cartStep);
    await tester.pumpAndSettle();

    final quantityField = find
        .descendant(
          of: find.byType(QuantityStepper).first,
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(quantityField, '1000');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(cartController.items.single.quantity, equals(1000));
    expect(cartController.canConfirm, isFalse);
  });

  testWidgets('products step shows compact scan button beside search', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'sales-scan-token',
    });

    Get.put<AuthRepository>(
      createRepository((request) async {
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
    Get.put<ProductRepository>(
      createProductRepository((request) async {
        if (request.method == 'GET' &&
            request.url.path.contains(
              '/inventory-manager/barcode/products/BC-001',
            )) {
          return http.Response(
            jsonEncode({'data': sampleProducts.first}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode(productListPayload(products: sampleProducts)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    Get.put<CustomerRepository>(
      createCustomerRepository((request) async {
        return http.Response(
          jsonEncode(customerListPayload(customers: sampleCustomers)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      permanent: true,
    );
    registerDefaultOrderRepository();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();

    final cartController = Get.find<CartController>();
    cartController.setSelectedCustomer(
      const CustomerModel(id: 1, name: 'Rahman Store'),
    );
    cartController.goToStep(CartController.productsStep);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Scan barcode'), findsOneWidget);
  });
}
