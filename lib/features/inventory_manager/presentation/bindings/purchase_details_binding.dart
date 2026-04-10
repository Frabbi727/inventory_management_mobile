import 'package:get/get.dart';

import '../controllers/purchase_details_controller.dart';
import 'inventory_manager_dependencies.dart';

class PurchaseDetailsBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => PurchaseDetailsController(inventoryManagerRepository: Get.find()),
    );
  }
}
