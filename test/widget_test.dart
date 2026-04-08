import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/app.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/core/storage/user_storage.dart';
import 'package:inventory_management_sales/features/auth/data/models/user_model.dart';
import 'package:inventory_management_sales/features/auth/data/repositories/auth_repository.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
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

    expect(find.text('Login'), findsOneWidget);
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

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsWidgets);
    expect(find.text('Fresh Milk 500ml'), findsOneWidget);
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

    final tokenStorage = TokenStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
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

    expect(find.text('Fresh Milk 500ml'), findsOneWidget);
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

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Fresh Milk 500ml'), findsOneWidget);

    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to Customer'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('ORD-2026-001'), findsOneWidget);

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

    final tokenStorage = TokenStorage();
    final userStorage = UserStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(await tokenStorage.getToken(), isNull);
    expect(await userStorage.getUser(), isNull);
  });
}
