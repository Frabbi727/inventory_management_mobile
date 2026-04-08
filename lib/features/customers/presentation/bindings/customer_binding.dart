import 'package:get/get.dart';

import '../controllers/customer_search_controller.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(CustomerSearchController.new);
  }
}
