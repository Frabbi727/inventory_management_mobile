import 'package:get/get.dart';

import '../controllers/product_list_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ProductListController.new);
  }
}
