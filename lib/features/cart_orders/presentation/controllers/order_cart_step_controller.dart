import 'package:flutter/material.dart';
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

  Future<void> pickIntendedDeliveryAt(BuildContext context) async {
    final now = DateTime.now();
    final initial = _cartController.selectedIntendedDeliveryAt.value ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null) {
      return;
    }

    _cartController.setIntendedDeliveryAt(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }
}
