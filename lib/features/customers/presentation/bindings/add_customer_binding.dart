import 'package:get/get.dart';

import '../controllers/add_customer_controller.dart';
import 'customer_dependencies.dart';

class AddCustomerBinding extends Bindings {
  @override
  void dependencies() {
    CustomerDependencies.ensureRegistered();
    Get.lazyPut(() => AddCustomerController(customerRepository: Get.find()));
  }
}
