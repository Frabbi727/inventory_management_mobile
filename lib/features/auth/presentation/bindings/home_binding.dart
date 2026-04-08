import 'package:get/get.dart';

import '../../../cart_orders/presentation/bindings/cart_dependencies.dart';
import '../../../invoice/presentation/controllers/invoice_controller.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../controllers/home_controller.dart';
import 'auth_dependencies.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    ProductDependencies.ensureRegistered();
    CartDependencies.ensureRegistered();

    if (!Get.isRegistered<ProductListController>()) {
      Get.lazyPut(
        () => ProductListController(
          productRepository: Get.find<ProductRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InvoiceController>()) {
      Get.lazyPut(InvoiceController.new, fenix: true);
    }

    Get.lazyPut(
      () => HomeController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
