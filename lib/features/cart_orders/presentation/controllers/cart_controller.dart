import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/create_order_request_model.dart';
import '../../data/models/create_order_response_model.dart';
import '../../data/models/order_item_request_model.dart';
import '../../data/repositories/order_repository.dart';

class CartController extends GetxController {
  static const int customerStep = 0;
  static const int productsStep = 1;
  static const int cartStep = 2;
  static const int confirmStep = 3;

  CartController({required OrderRepository orderRepository})
    : _orderRepository = orderRepository;

  final OrderRepository _orderRepository;

  final items = <CartItemModel>[].obs;
  final selectedCustomer = Rxn<CustomerModel>();
  final currentStep = 0.obs;
  final discountType = RxnString();
  final discountValue = Rxn<num>();
  final noteText = ''.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  final noteController = TextEditingController();
  final discountValueController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    noteController.addListener(_syncNoteText);
    discountValueController.addListener(_syncDiscountValue);
  }

  int _indexOfProduct(int? productId) {
    if (productId == null) {
      return -1;
    }

    return items.indexWhere((item) => item.productId == productId);
  }

  bool addProduct(ProductModel product) {
    final productId = product.id;
    if (productId == null) {
      return false;
    }

    final currentStock = product.currentStock;
    if (currentStock != null && currentStock <= 0) {
      return false;
    }

    final existingIndex = _indexOfProduct(productId);
    if (existingIndex == -1) {
      items.add(CartItemModel(product: product, quantity: 1));
      errorMessage.value = null;
      return true;
    }

    final existingItem = items[existingIndex];
    final nextQuantity = existingItem.quantity + 1;
    if (currentStock != null && nextQuantity > currentStock) {
      return false;
    }

    items[existingIndex] = existingItem.copyWith(quantity: nextQuantity);
    items.refresh();
    errorMessage.value = null;
    return true;
  }

  bool canIncrementQuantity(int? productId) {
    final index = _indexOfProduct(productId);
    if (index == -1) {
      return false;
    }

    final currentItem = items[index];
    final currentStock = currentItem.product.currentStock;
    if (currentStock == null) {
      return true;
    }

    return currentItem.quantity < currentStock;
  }

  bool incrementQuantity(int? productId) {
    final index = _indexOfProduct(productId);
    if (index == -1) {
      return false;
    }

    final currentItem = items[index];
    final currentStock = currentItem.product.currentStock;
    final nextQuantity = currentItem.quantity + 1;
    if (currentStock != null && nextQuantity > currentStock) {
      errorMessage.value =
          'Only ${currentStock.toInt()} unit(s) available for ${currentItem.product.name ?? 'this product'}.';
      return false;
    }

    items[index] = currentItem.copyWith(quantity: nextQuantity);
    items.refresh();
    errorMessage.value = null;
    return true;
  }

  void decrementQuantity(int? productId) {
    final index = _indexOfProduct(productId);
    if (index == -1) {
      return;
    }

    final currentItem = items[index];
    final currentQuantity = currentItem.quantity;
    if (currentQuantity <= 1) {
      removeItem(productId);
      return;
    }

    items[index] = currentItem.copyWith(quantity: currentQuantity - 1);
    items.refresh();
    errorMessage.value = null;
  }

  void removeItem(int? productId) {
    final index = _indexOfProduct(productId);
    if (index == -1) {
      return;
    }

    items.removeAt(index);
    errorMessage.value = null;
    if (items.isEmpty && currentStep.value > productsStep) {
      currentStep.value = productsStep;
    }
  }

  CartItemModel? itemByProductId(int? productId) {
    final index = _indexOfProduct(productId);
    if (index == -1) {
      return null;
    }

    return items[index];
  }

  bool containsProduct(int? productId) => _indexOfProduct(productId) != -1;

  bool get hasCustomerSelected => selectedCustomer.value?.id != null;

  bool get hasItems => items.isNotEmpty;

  bool get showFooterTotals => currentStep.value != customerStep && hasItems;

  bool get isDiscountEnabled => discountType.value != null;

  String? get apiDiscountType {
    if (_isPercentageDiscount(discountType.value)) {
      return 'percentage';
    }

    return discountType.value;
  }

  num? get appliedDiscountValue {
    final rawValue = discountValue.value;
    if (rawValue == null) {
      return null;
    }

    if (_isPercentageDiscount(discountType.value)) {
      return _normalizeMoney(rawValue.clamp(0, 100));
    }

    return _normalizeMoney(rawValue < 0 ? 0 : rawValue);
  }

  bool get canContinueCurrentStep {
    switch (currentStep.value) {
      case customerStep:
        return true;
      case productsStep:
      case cartStep:
        return true;
      default:
        return !isSubmitting.value;
    }
  }

  bool canGoToStep(int step) {
    return step >= customerStep && step <= confirmStep;
  }

  void clearCart() {
    items.clear();
    selectedCustomer.value = null;
    currentStep.value = customerStep;
    discountType.value = null;
    discountValue.value = null;
    noteText.value = '';
    noteController.clear();
    discountValueController.clear();
    errorMessage.value = null;
  }

  void startNewOrder() {
    clearCart();
    currentStep.value = customerStep;
  }

  void setSelectedCustomer(CustomerModel? customer) {
    selectedCustomer.value = customer;
    errorMessage.value = null;
  }

  void nextStep() {
    errorMessage.value = validationMessageForStep(currentStep.value);
    if (currentStep.value < confirmStep) {
      currentStep.value += 1;
    }
  }

  void previousStep() {
    errorMessage.value = null;
    if (currentStep.value > customerStep) {
      currentStep.value -= 1;
    }
  }

  void goToStep(int step) {
    if (!canGoToStep(step)) {
      return;
    }

    errorMessage.value = validationMessageForStep(step);
    currentStep.value = step;
  }

  void setDiscountType(String? value) {
    if (value == null || value == 'none') {
      discountType.value = null;
      discountValue.value = null;
      discountValueController.clear();
      return;
    }

    discountType.value = _isPercentageDiscount(value) ? 'percentage' : value;
    if (discountValueController.text.trim().isNotEmpty) {
      _syncDiscountValue();
    }
  }

  void onDiscountValueChanged(String value) {
    discountValue.value = _parseDiscountValue(value.trim());
  }

  void normalizeDiscountInputText() {
    final normalizedValue = appliedDiscountValue;
    if (normalizedValue == null) {
      if (discountValueController.text.isNotEmpty) {
        discountValueController.clear();
      }
      return;
    }

    final normalizedText = normalizedValue.toStringAsFixed(2);
    if (discountValueController.text == normalizedText) {
      return;
    }

    discountValueController.value = TextEditingValue(
      text: normalizedText,
      selection: TextSelection.collapsed(offset: normalizedText.length),
    );
  }

  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);

  num get subtotal => _normalizeMoney(
    items.fold<num>(0, (sum, item) => sum + item.lineTotal),
  );

  num get estimatedDiscountAmount {
    final rawValue = appliedDiscountValue;
    if (rawValue == null || rawValue <= 0) {
      return 0;
    }

    if (_isPercentageDiscount(discountType.value)) {
      return _normalizeMoney(subtotal * (rawValue / 100));
    }

    return _normalizeMoney(rawValue > subtotal ? subtotal : rawValue);
  }

  num get grandTotal {
    final total = subtotal - estimatedDiscountAmount;
    return _normalizeMoney(total < 0 ? 0 : total);
  }

  bool get canSubmit =>
      !isSubmitting.value &&
      selectedCustomer.value?.id != null &&
      items.isNotEmpty;

  String? validationMessageForStep(int step) {
    if (step >= productsStep && !hasCustomerSelected) {
      return 'Select a customer before finalizing this order.';
    }

    if (step >= cartStep && !hasItems) {
      return 'Add at least one product before reviewing the cart.';
    }

    return null;
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '৳0.00';
    }

    return '৳${_normalizeMoney(value).toStringAsFixed(2)}';
  }

  Future<CreateOrderResponseModel?> submitOrder() async {
    if (selectedCustomer.value?.id == null) {
      errorMessage.value = 'Select a customer before submitting the order.';
      return null;
    }

    if (items.isEmpty) {
      errorMessage.value = 'Add at least one product to create an order.';
      return null;
    }

    errorMessage.value = null;
    isSubmitting.value = true;

    try {
      final request = CreateOrderRequestModel(
        customerId: selectedCustomer.value?.id,
        orderDate: _formatDate(DateTime.now()),
        note: noteText.value.trim().isEmpty ? null : noteText.value.trim(),
        discountType: apiDiscountType,
        discountValue: appliedDiscountValue,
        items: items
            .where((item) => item.productId != null)
            .map(
              (item) => OrderItemRequestModel(
                productId: item.productId,
                quantity: item.quantity,
              ),
            )
            .toList(),
      );

      final response = await _orderRepository.createOrder(request);
      if (Get.key.currentState != null) {
        Get.toNamed(AppRoutes.orderSuccess, arguments: response);
      }
      clearCart();
      return response;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to submit the order right now.';
    } finally {
      isSubmitting.value = false;
    }

    return null;
  }

  String submitButtonLabel() {
    switch (currentStep.value) {
      case customerStep:
        return 'Continue to Products';
      case productsStep:
        return 'Review Cart';
      case cartStep:
        return 'Continue to Confirm';
      default:
        return 'Submit Order';
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _syncNoteText() {
    noteText.value = noteController.text;
  }

  void _syncDiscountValue() {
    if (!isDiscountEnabled) {
      discountValue.value = null;
      return;
    }

    final rawValue = discountValueController.text.trim();
    if (rawValue.isEmpty) {
      discountValue.value = null;
      return;
    }

    discountValue.value = _parseDiscountValue(rawValue);
  }

  num _normalizeMoney(num value) {
    return num.parse(value.toStringAsFixed(2));
  }

  num? _parseDiscountValue(String rawValue) {
    final parsedValue = num.tryParse(rawValue);
    if (parsedValue == null) {
      return null;
    }

    final nonNegativeValue = parsedValue < 0 ? 0 : parsedValue;
    if (_isPercentageDiscount(discountType.value)) {
      return _normalizeMoney(nonNegativeValue.clamp(0, 100));
    }

    return _normalizeMoney(nonNegativeValue);
  }

  bool _isPercentageDiscount(String? value) {
    return value == 'percentage' || value == 'percent';
  }

  @override
  void onClose() {
    noteController.removeListener(_syncNoteText);
    discountValueController.removeListener(_syncDiscountValue);
    noteController.dispose();
    discountValueController.dispose();
    super.onClose();
  }
}
