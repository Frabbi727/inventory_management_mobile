import 'package:get/get.dart';

import '../controllers/inventory_summary_controller.dart';
import 'inventory_manager_dependencies.dart';

class InventorySummaryBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    if (!Get.isRegistered<InventorySummaryController>()) {
      Get.lazyPut(
        () => InventorySummaryController(productRepository: Get.find()),
        fenix: true,
      );
    }
  }
}
