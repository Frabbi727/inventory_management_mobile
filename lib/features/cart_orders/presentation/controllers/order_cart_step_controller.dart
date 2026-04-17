import 'package:get/get.dart';

import '../../data/models/cart_item_model.dart';
import 'cart_controller.dart';

class OrderCartStepController extends GetxController {
  OrderCartStepController({required CartController cartController})
    : _cartController = cartController;

  final CartController _cartController;

  CartController get cartController => _cartController;
  List<CartItemModel> get items => _cartController.items;

  void incrementQuantity(String lineKey) {
    _cartController.incrementQuantity(lineKey);
  }

  void decrementQuantity(String lineKey) {
    _cartController.decrementQuantity(lineKey);
  }

  void updateQuantity(String lineKey, int quantity) {
    _cartController.setLineQuantity(lineKey, quantity);
  }

  void removeItem(String lineKey) {
    _cartController.removeItem(lineKey);
  }

  void goToProductsStep() {
    _cartController.goToStep(CartController.productsStep);
  }
}
