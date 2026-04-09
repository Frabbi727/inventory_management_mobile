import 'package:get/get.dart';

import '../../../cart_orders/data/repositories/order_repository.dart';
import '../controllers/order_details_controller.dart';

class OrderDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () =>
          OrderDetailsController(orderRepository: Get.find<OrderRepository>()),
    );
  }
}
