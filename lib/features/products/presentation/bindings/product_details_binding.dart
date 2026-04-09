import 'package:get/get.dart';

import '../controllers/product_details_controller.dart';
import 'product_dependencies.dart';

class ProductDetailsBinding extends Bindings {
  @override
  void dependencies() {
    ProductDependencies.ensureRegistered();
    Get.lazyPut(() => ProductDetailsController(productRepository: Get.find()));
  }
}
