import 'package:get/get.dart';

import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../controllers/product_details_controller.dart';
import 'product_dependencies.dart';

class ProductDetailsBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    ProductDependencies.ensureRegistered();
    Get.lazyPut(
      () => ProductDetailsController(
        productRepository: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
