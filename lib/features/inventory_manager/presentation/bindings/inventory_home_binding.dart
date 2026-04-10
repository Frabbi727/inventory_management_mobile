import 'package:get/get.dart';

import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../controllers/inventory_home_controller.dart';
import '../controllers/purchase_draft_controller.dart';

class InventoryHomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    ProductDependencies.ensureRegistered();

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

    if (!Get.isRegistered<ProductListController>()) {
      Get.lazyPut(
        () => ProductListController(productRepository: Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InventoryHomeController>()) {
      Get.lazyPut(
        () => InventoryHomeController(
          authRepository: Get.find(),
          tokenStorage: Get.find(),
          userStorage: Get.find(),
        ),
      );
    }

    if (!Get.isRegistered<PurchaseDraftController>()) {
      Get.put(PurchaseDraftController(), permanent: true);
    }
  }
}
