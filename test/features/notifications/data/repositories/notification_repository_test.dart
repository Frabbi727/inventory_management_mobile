import 'dart:convert';

import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'shell-token',
    });
  });

  NotificationRepository createRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return NotificationRepository(
      apiClient: ApiClient(httpClient: MockClient(handler)),
      tokenStorage: TokenStorage(),
    );
  }

  test('fetchNotifications sends unread filter and parses paginator payload', () async {
    late http.Request capturedRequest;
    final repository = createRepository((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 101,
              'type': 'order.confirmed',
              'title': 'Order confirmed',
              'body': 'Your order ORD-1005 has been confirmed.',
              'is_read': false,
              'read_at': null,
              'created_at': '2026-04-18T10:30:00.000000Z',
              'entity': {'type': 'order', 'id': 55},
              'data': {'order_no': 'ORD-1005'},
            },
          ],
          'links': {
            'first': 'http://localhost/api/notifications?page=1',
            'last': 'http://localhost/api/notifications?page=1',
            'prev': null,
            'next': null,
          },
          'meta': {
            'current_page': 1,
            'from': 1,
            'last_page': 1,
            'path': 'http://localhost/api/notifications',
            'per_page': 15,
            'to': 1,
            'total': 1,
            'links': [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await repository.fetchNotifications(status: 'unread');

    expect(capturedRequest.url.path, '/api/notifications');
    expect(capturedRequest.url.queryParameters['status'], 'unread');
    expect(response.data, hasLength(1));
    expect(response.data!.first.entity?.id, 55);
    expect(response.data!.first.isRead, isFalse);
  });

  test('fetchUnreadCount parses count response', () async {
    final repository = createRepository((_) async {
      return http.Response(
        jsonEncode({'count': 3}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await repository.fetchUnreadCount();

    expect(response.count, 3);
  });

  test('mark read, unread, and read-all use contract paths', () async {
    final paths = <String>[];
    final repository = createRepository((request) async {
      paths.add(request.url.path);
      return http.Response(
        jsonEncode({'message': 'OK'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await repository.markAsRead(101);
    await repository.markAsUnread(101);
    await repository.markAllAsRead();

    expect(paths, [
      '/api/notifications/101/read',
      '/api/notifications/101/unread',
      '/api/notifications/read-all',
    ]);
  });
}
