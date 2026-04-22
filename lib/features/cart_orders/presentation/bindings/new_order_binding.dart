import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../customers/presentation/bindings/customer_dependencies.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import 'cart_dependencies.dart';
import '../controllers/new_order_page_controller.dart';
import '../controllers/order_cart_step_controller.dart';
import '../controllers/order_confirm_step_controller.dart';
import '../controllers/order_customer_step_controller.dart';
import '../controllers/order_payment_step_controller.dart';
import '../controllers/order_products_step_controller.dart';

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

    if (!Get.isRegistered<OrderCustomerStepController>()) {
      Get.lazyPut(
        () => OrderCustomerStepController(
          cartController: Get.find(),
          customerSearchController: Get.find(
            tag: ControllerTags.newOrderCustomerSearch,
          ),
        ),
      );
    }

    if (!Get.isRegistered<NewOrderPageController>()) {
      Get.lazyPut(() => NewOrderPageController(cartController: Get.find()));
    }

    if (!Get.isRegistered<OrderProductsStepController>()) {
      Get.lazyPut(
        () => OrderProductsStepController(
          cartController: Get.find(),
          productListController: Get.find(
            tag: ControllerTags.newOrderProductSearch,
          ),
          productRepository: Get.find(),
        ),
      );
    }

    if (!Get.isRegistered<OrderCartStepController>()) {
      Get.lazyPut(() => OrderCartStepController(cartController: Get.find()));
    }

    if (!Get.isRegistered<OrderPaymentStepController>()) {
      Get.lazyPut(() => OrderPaymentStepController(cartController: Get.find()));
    }

    if (!Get.isRegistered<OrderConfirmStepController>()) {
      Get.lazyPut(() => OrderConfirmStepController(cartController: Get.find()));
    }
  }
}
