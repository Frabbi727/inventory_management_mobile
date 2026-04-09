import 'package:get/get.dart';

import '../../../cart_orders/data/repositories/order_repository.dart';
import '../controllers/invoice_controller.dart';

class InvoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => InvoiceController(orderRepository: Get.find<OrderRepository>()),
    );
  }
}
