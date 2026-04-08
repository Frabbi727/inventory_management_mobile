import 'package:get/get.dart';

import '../controllers/customer_search_controller.dart';
import 'customer_dependencies.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    CustomerDependencies.ensureRegistered();
    Get.lazyPut(() => CustomerSearchController(customerRepository: Get.find()));
  }
}
