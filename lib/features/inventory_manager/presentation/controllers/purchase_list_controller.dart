import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import 'purchase_records_controller.dart';

class PurchaseListController extends PurchaseRecordsController {
  PurchaseListController({required super.inventoryManagerRepository});

  Future<void> openNewPurchase() async {
    final result = await Get.toNamed(AppRoutes.inventoryPurchaseCreate);
    if (result != null) {
      await fetchPurchases(reset: true);
    }
  }
}
