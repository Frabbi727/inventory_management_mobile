import 'package:get/get.dart';

import '../controllers/edit_purchase_controller.dart';
import 'inventory_manager_dependencies.dart';

class EditPurchaseBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => EditPurchaseController(inventoryManagerRepository: Get.find()),
    );
  }
}
