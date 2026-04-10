import 'package:get/get.dart';

import '../controllers/purchase_list_controller.dart';
import 'inventory_manager_dependencies.dart';

class PurchaseListBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    if (!Get.isRegistered<PurchaseListController>()) {
      Get.lazyPut(PurchaseListController.new, fenix: true);
    }
  }
}
