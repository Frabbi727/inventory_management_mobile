import 'package:get/get.dart';

import '../../../customers/presentation/bindings/customer_dependencies.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import 'cart_dependencies.dart';

class NewOrderBinding extends Bindings {
  @override
  void dependencies() {
    ProductDependencies.ensureRegistered();
    CustomerDependencies.ensureRegistered();
    CartDependencies.ensureRegistered();

    if (!Get.isRegistered<ProductListController>()) {
      Get.lazyPut(
        () => ProductListController(productRepository: Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CustomerSearchController>()) {
      Get.lazyPut(
        () => CustomerSearchController(customerRepository: Get.find()),
        fenix: true,
      );
    }
  }
}
