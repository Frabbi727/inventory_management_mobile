import 'package:get/get.dart';

import '../models/order_flow_step.dart';
import '../pages/new_order/order_cart_step_page.dart';
import '../pages/new_order/order_confirm_step_page.dart';
import '../pages/new_order/order_customer_step_page.dart';
import '../pages/new_order/order_payment_step_page.dart';
import '../pages/new_order/order_products_step_page.dart';
import 'cart_controller.dart';

class NewOrderPageController extends GetxController {
  NewOrderPageController({required CartController cartController})
    : _cartController = cartController;

  final CartController _cartController;

  late final List<OrderFlowStep> steps = <OrderFlowStep>[
    OrderFlowStep(
      index: CartController.customerStep,
      title: 'Customer',
      builder: (_) => const OrderCustomerStepPage(),
    ),
    OrderFlowStep(
      index: CartController.productsStep,
      title: 'Products',
      builder: (_) => const OrderProductsStepPage(),
    ),
    OrderFlowStep(
      index: CartController.cartStep,
      title: 'Cart',
      builder: (_) => const OrderCartStepPage(),
    ),
    OrderFlowStep(
      index: CartController.paymentStep,
      title: 'Payment',
      builder: (_) => const OrderPaymentStepPage(),
    ),
    OrderFlowStep(
      index: CartController.confirmStep,
      title: 'Confirm',
      builder: (_) => const OrderConfirmStepPage(),
    ),
  ];

  CartController get cartController => _cartController;

  List<String> get stepTitles =>
      steps.map((step) => step.title).toList(growable: false);

  String primaryLabel(int step) {
    if (step == CartController.confirmStep && !cartController.canConfirm) {
      if (!cartController.isPaymentComplete) {
        return 'Complete Payment';
      }
      return 'Resolve Stock Warnings';
    }

    return cartController.submitButtonLabel();
  }
}
