import 'package:get/get.dart';

import '../controllers/purchase_records_controller.dart';
import 'inventory_manager_dependencies.dart';

class PurchaseRecordsBinding extends Bindings {
  @override
  void dependencies() {
    InventoryManagerDependencies.ensureRegistered();
    Get.lazyPut(
      () => PurchaseRecordsController(inventoryManagerRepository: Get.find()),
    );
  }
}
