import 'package:get/get.dart';

import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../controllers/inventory_home_controller.dart';
import 'inventory_manager_dependencies.dart';
import 'inventory_products_binding.dart';
import 'inventory_summary_binding.dart';
import 'purchase_list_binding.dart';

class InventoryHomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    InventoryManagerDependencies.ensureRegistered();
    InventoryProductsBinding().dependencies();
    PurchaseListBinding().dependencies();
    InventorySummaryBinding().dependencies();

    if (!Get.isRegistered<InventoryHomeController>()) {
      Get.lazyPut(
        () => InventoryHomeController(
          authRepository: Get.find(),
          tokenStorage: Get.find(),
          userStorage: Get.find(),
        ),
      );
    }
  }
}
