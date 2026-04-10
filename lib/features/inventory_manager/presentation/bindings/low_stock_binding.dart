import 'package:get/get.dart';

import '../controllers/low_stock_controller.dart';
import 'inventory_manager_dependencies.dart';

class LowStockBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    if (!Get.isRegistered<LowStockController>()) {
      Get.lazyPut(
        () => LowStockController(productRepository: Get.find()),
        fenix: true,
      );
    }
  }
}
