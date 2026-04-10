import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class InventoryManagerDependencies {
  InventoryManagerDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();
    ProductDependencies.ensureRegistered();

    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<InventoryManagerRepository>()) {
      Get.lazyPut(
        () => InventoryManagerRepository(
          productRepository: Get.find(),
          apiClient: Get.find(),
          tokenStorage: Get.find(),
        ),
        fenix: true,
      );
    }
  }
}
