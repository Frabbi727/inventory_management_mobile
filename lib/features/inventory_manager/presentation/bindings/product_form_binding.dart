import 'package:get/get.dart';

import '../controllers/product_form_controller.dart';
import 'inventory_manager_dependencies.dart';

class ProductFormBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => ProductFormController(inventoryManagerRepository: Get.find()),
    );
  }
}
