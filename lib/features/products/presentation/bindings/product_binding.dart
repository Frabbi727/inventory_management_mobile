import 'package:get/get.dart';

import '../controllers/product_list_controller.dart';
import 'product_dependencies.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    ProductDependencies.ensureRegistered();
    Get.lazyPut(
      () => ProductListController(productRepository: Get.find()),
      fenix: true,
    );
  }
}
