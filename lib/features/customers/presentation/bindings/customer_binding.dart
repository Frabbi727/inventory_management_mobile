import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../controllers/customer_search_controller.dart';
import 'customer_dependencies.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    CustomerDependencies.ensureRegistered();
    if (!Get.isRegistered<CustomerSearchController>(
      tag: ControllerTags.customerSearchRoute,
    )) {
      Get.lazyPut(
        () => CustomerSearchController(customerRepository: Get.find()),
        tag: ControllerTags.customerSearchRoute,
      );
    }
  }
}
