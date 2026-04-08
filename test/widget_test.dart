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

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Home screen placeholder'), findsOneWidget);
    expect(find.text('Name: Sales Demo'), findsOneWidget);
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

    expect(find.text('Home screen placeholder'), findsOneWidget);
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

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'bad-user');
    await tester.enterText(find.byType(TextFormField).last, 'bad-pass');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials.'), findsOneWidget);
    expect(find.text('Home screen placeholder'), findsNothing);
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

    final tokenStorage = TokenStorage();
    final userStorage = UserStorage();

    await tester.pumpWidget(const SalesApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(await tokenStorage.getToken(), isNull);
    expect(await userStorage.getUser(), isNull);
  });
}
