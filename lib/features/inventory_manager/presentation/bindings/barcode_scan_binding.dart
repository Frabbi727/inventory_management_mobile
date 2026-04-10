import 'package:get/get.dart';

import '../controllers/barcode_scan_controller.dart';
import 'inventory_manager_dependencies.dart';

class BarcodeScanBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => BarcodeScanController(inventoryManagerRepository: Get.find()),
    );
  }
}
