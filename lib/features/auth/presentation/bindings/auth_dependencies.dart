import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_token_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/device_token_provider.dart';

class AuthDependencies {
  AuthDependencies._();

  static void ensureRegistered() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<DeviceTokenStorage>()) {
      Get.lazyPut(DeviceTokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<UserStorage>()) {
      Get.lazyPut(UserStorage.new, fenix: true);
    }

    if (!Get.isRegistered<DeviceTokenProvider>()) {
      Get.lazyPut<DeviceTokenProvider>(FirebaseDeviceTokenProvider.new, fenix: true);
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut(
        () => AuthRepository(
          apiClient: Get.find<ApiClient>(),
          deviceTokenProvider: Get.find<DeviceTokenProvider>(),
          deviceTokenStorage: Get.find<DeviceTokenStorage>(),
        ),
        fenix: true,
      );
    }
  }
}
