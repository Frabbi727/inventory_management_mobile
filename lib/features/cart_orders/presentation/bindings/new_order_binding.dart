import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
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

    if (!Get.isRegistered<ProductListController>(
      tag: ControllerTags.newOrderProductSearch,
    )) {
      Get.lazyPut(
        () => ProductListController(productRepository: Get.find()),
        tag: ControllerTags.newOrderProductSearch,
      );
    }

    if (!Get.isRegistered<CustomerSearchController>(
      tag: ControllerTags.newOrderCustomerSearch,
    )) {
      Get.lazyPut(
        () => CustomerSearchController(customerRepository: Get.find()),
        tag: ControllerTags.newOrderCustomerSearch,
      );
    }
  }
}
