import 'package:get/get.dart';

import '../controllers/create_purchase_controller.dart';
import 'inventory_manager_dependencies.dart';

class CreatePurchaseBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => CreatePurchaseController(
        productRepository: Get.find(),
        inventoryManagerRepository: Get.find(),
      ),
    );
  }
}
