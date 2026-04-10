import 'package:get/get.dart';

import '../controllers/purchase_view_controller.dart';
import 'inventory_manager_dependencies.dart';

class PurchaseViewBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => PurchaseViewController(inventoryManagerRepository: Get.find()),
    );
  }
}
