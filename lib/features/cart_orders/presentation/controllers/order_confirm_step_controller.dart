import 'package:get/get.dart';

import 'cart_controller.dart';

class OrderConfirmStepController extends GetxController {
  OrderConfirmStepController({required CartController cartController})
    : _cartController = cartController;

  final CartController _cartController;

  CartController get cartController => _cartController;
}
