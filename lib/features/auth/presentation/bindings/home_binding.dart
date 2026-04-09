import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../cart_orders/presentation/bindings/cart_dependencies.dart';
import '../../../customers/presentation/bindings/customer_dependencies.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../invoice/presentation/controllers/invoice_controller.dart';
import '../controllers/home_controller.dart';
import 'auth_dependencies.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    CustomerDependencies.ensureRegistered();
    CartDependencies.ensureRegistered();

    if (!Get.isRegistered<CustomerSearchController>(
      tag: ControllerTags.homeCustomerSearch,
    )) {
      Get.lazyPut(
        () => CustomerSearchController(customerRepository: Get.find()),
        tag: ControllerTags.homeCustomerSearch,
      );
    }

    if (!Get.isRegistered<InvoiceController>()) {
      Get.lazyPut(
        () => InvoiceController(orderRepository: Get.find()),
        fenix: true,
      );
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
