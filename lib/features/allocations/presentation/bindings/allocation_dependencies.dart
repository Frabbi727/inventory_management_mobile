import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../data/repositories/allocation_repository.dart';
import '../controllers/allocation_controller.dart';

class AllocationDependencies {
  AllocationDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();

    if (!Get.isRegistered<AllocationRepository>()) {
      Get.lazyPut(
        () => AllocationRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AllocationController>()) {
      Get.put(
        AllocationController(
          allocationRepository: Get.find<AllocationRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
