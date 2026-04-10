import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';

class PurchaseListController extends GetxController {
  void openNewPurchase() {
    Get.toNamed(AppRoutes.inventoryPurchaseCreate);
  }
}
