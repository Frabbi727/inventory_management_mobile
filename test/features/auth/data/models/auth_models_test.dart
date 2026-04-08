import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_sales/features/auth/data/models/login_request_model.dart';
import 'package:inventory_management_sales/features/auth/data/models/login_response_model.dart';
import 'package:inventory_management_sales/features/auth/data/models/profile_response_model.dart';

void main() {
  test('login response parses with missing optional fields', () {
    final model = LoginResponseModel.fromJson({
      'message': 'Login successful.',
      'data': {
        'token': 'abc123',
        'user': {'id': 2, 'name': 'Sales Demo'},
      },
    });

    expect(model.message, 'Login successful.');
    expect(model.data?.token, 'abc123');
    expect(model.data?.tokenType, isNull);
    expect(model.data?.user?.name, 'Sales Demo');
    expect(model.data?.user?.email, isNull);
    expect(model.data?.user?.role, isNull);
  });

  test('profile response tolerates nullable nested fields', () {
    final model = ProfileResponseModel.fromJson({
      'data': {'id': 2, 'name': 'Sales Demo', 'email': null, 'role': null},
    });

    expect(model.data?.id, 2);
    expect(model.data?.email, isNull);
    expect(model.data?.role, isNull);
  });

  test('login request toJson emits expected payload keys', () {
    final request = LoginRequestModel(
      login: 'salesman@example.com',
      password: 'secret',
      deviceName: 'flutter-mobile',
    );

    expect(request.toJson(), {
      'login': 'salesman@example.com',
      'password': 'secret',
      'device_name': 'flutter-mobile',
    });
  });
}
