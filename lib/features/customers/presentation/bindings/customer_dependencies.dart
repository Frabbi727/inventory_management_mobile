import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_dependencies.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../data/repositories/customer_cache_repository.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerDependencies {
  CustomerDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();
    OfflineDependencies.ensureRegistered();

    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<CustomerCacheRepository>()) {
      Get.lazyPut(CustomerCacheRepository.new, fenix: true);
    }

    if (!Get.isRegistered<CustomerRepository>()) {
      Get.lazyPut(
        () => CustomerRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
          customerCacheRepository: Get.find<CustomerCacheRepository>(),
          pendingActionsRepository: Get.find<PendingActionsRepository>(),
        ),
        fenix: true,
      );
    }
  }
}
