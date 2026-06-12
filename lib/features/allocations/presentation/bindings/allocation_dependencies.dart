import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_dependencies.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../data/repositories/allocation_cache_repository.dart';
import '../../data/repositories/allocation_repository.dart';
import '../controllers/allocation_controller.dart';

class AllocationDependencies {
  AllocationDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();
    OfflineDependencies.ensureRegistered();

    if (!Get.isRegistered<AllocationRepository>()) {
      Get.lazyPut(
        () => AllocationRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
          pendingActionsRepository: Get.find<PendingActionsRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AllocationCacheRepository>()) {
      Get.lazyPut(AllocationCacheRepository.new, fenix: true);
    }

    if (!Get.isRegistered<AllocationController>()) {
      Get.put(
        AllocationController(
          allocationRepository: Get.find<AllocationRepository>(),
          allocationCacheRepository: Get.find<AllocationCacheRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
