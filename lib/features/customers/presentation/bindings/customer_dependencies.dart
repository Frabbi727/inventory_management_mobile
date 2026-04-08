import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerDependencies {
  CustomerDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();

    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<CustomerRepository>()) {
      Get.lazyPut(
        () => CustomerRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
        ),
        fenix: true,
      );
    }
  }
}
