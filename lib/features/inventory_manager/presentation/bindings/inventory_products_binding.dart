import 'package:get/get.dart';

import '../controllers/inventory_products_controller.dart';
import 'inventory_manager_dependencies.dart';

class InventoryProductsBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    if (!Get.isRegistered<InventoryProductsController>()) {
      Get.lazyPut(
        () => InventoryProductsController(productRepository: Get.find()),
        fenix: true,
      );
    }
  }
}
