import 'package:get/get.dart';

import '../../data/repositories/customer_cache_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../controllers/customer_search_controller.dart';
import 'customer_dependencies.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    CustomerDependencies.ensureRegistered();

    if (!Get.isRegistered<CustomerSearchController>()) {
      Get.lazyPut(
        () => CustomerSearchController(
          customerRepository: Get.find<CustomerRepository>(),
          customerCacheRepository: Get.find<CustomerCacheRepository>(),
        ),
      );
    }
  }
}
