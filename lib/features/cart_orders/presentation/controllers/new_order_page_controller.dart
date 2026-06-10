import 'package:get/get.dart';

import '../models/order_flow_step.dart';
import '../pages/new_order/order_customer_step_page.dart';
import '../pages/new_order/order_payment_step_page.dart';
import '../pages/new_order/order_products_step_page.dart';
import '../pages/new_order/order_review_step_page.dart';
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
      index: CartController.reviewStep,
      title: 'Review',
      builder: (_) => const OrderReviewStepPage(),
    ),
    OrderFlowStep(
      index: CartController.paymentStep,
      title: 'Payment',
      builder: (_) => const OrderPaymentStepPage(),
    ),
  ];

  CartController get cartController => _cartController;

  List<String> get stepTitles =>
      steps.map((step) => step.title).toList(growable: false);

  String primaryLabel(int step) {
    if (step == CartController.paymentStep && !cartController.canConfirm) {
      if (!cartController.isPaymentComplete) {
        return 'Complete Payment';
      }
      if (cartController.hasKnownStockIssues) {
        return 'Resolve Stock Warnings';
      }
    }

    return cartController.submitButtonLabel();
  }
}
