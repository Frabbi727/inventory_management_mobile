import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/repositories/auth_repository.dart';

class AuthDependencies {
  AuthDependencies._();

  static void ensureRegistered() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<UserStorage>()) {
      Get.lazyPut(UserStorage.new, fenix: true);
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut(
        () => AuthRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
  }
}
