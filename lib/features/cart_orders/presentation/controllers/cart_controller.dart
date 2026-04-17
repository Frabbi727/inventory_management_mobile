import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/create_order_request_model.dart';
import '../../data/models/create_order_response_model.dart';
import '../../data/models/order_item_request_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class CartController extends GetxController {
  static const int customerStep = 0;
  static const int productsStep = 1;
  static const int cartStep = 2;
  static const int confirmStep = 3;

  CartController({
    required OrderRepository orderRepository,
    required ProductRepository productRepository,
  }) : _orderRepository = orderRepository,
       _productRepository = productRepository;

  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  final items = <CartItemModel>[].obs;
  final selectedCustomer = Rxn<CustomerModel>();
  final currentStep = 0.obs;
  final discountType = RxnString();
  final discountValue = Rxn<num>();
  final noteText = ''.obs;
  final selectedOrderDate = DateTime.now().obs;
  final savedDraftOrder = Rxn<OrderModel>();
  final isSubmitting = false.obs;
  final isHydratingDraft = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final hasUnsavedDraftChanges = false.obs;

  final noteController = TextEditingController();
  final discountValueController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    noteController.addListener(_syncNoteText);
    discountValueController.addListener(_syncDiscountValue);
  }

  int _indexOfLine(int? productId, int? productVariantId) {
    if (productId == null) {
      return -1;
    }

    return items.indexWhere(
      (item) =>
          item.productId == productId &&
          item.productVariantId == productVariantId,
    );
  }

  String lineKeyFor(int? productId, {int? productVariantId}) =>
      '${productId ?? 'unknown'}:${productVariantId ?? 'base'}';

  bool addProduct(
    ProductModel product, {
    ProductVariantModel? variant,
    int quantity = 1,
  }) {
    final productId = product.id;
    if (productId == null) {
      return false;
    }

    if (quantity <= 0) {
      errorMessage.value = 'Quantity must be greater than zero.';
      return false;
    }

    if (product.hasVariants == true && variant == null) {
      errorMessage.value = 'Select a variant before adding this product.';
      return false;
    }

    final currentStock = variant?.currentStock ?? product.currentStock;
    if (currentStock != null && currentStock <= 0) {
      errorMessage.value =
          '${variant?.combinationLabel ?? product.name ?? 'This product'} is currently unavailable.';
      return false;
    }

    final existingIndex = _indexOfLine(productId, variant?.id);
    if (existingIndex == -1) {
      items.add(
        CartItemModel(product: product, quantity: quantity, variant: variant),
      );
      _markDraftDirty();
      errorMessage.value = null;
      return true;
    }

    return _setItemQuantityAt(
      existingIndex,
      items[existingIndex].quantity + quantity,
    );
  }

  bool canIncrementQuantity(String lineKey) {
    final index = items.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return false;
    }

    final currentStock = items[index].availableStock;
    return currentStock == null || currentStock > 0;
  }

  bool incrementQuantity(String lineKey) {
    final index = items.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return false;
    }

    return _setItemQuantityAt(index, items[index].quantity + 1);
  }

  void decrementQuantity(String lineKey) {
    final index = items.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return;
    }

    setLineQuantity(lineKey, items[index].quantity - 1);
  }

  void removeItem(String lineKey) {
    final index = items.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return;
    }

    items.removeAt(index);
    _markDraftDirty();
    errorMessage.value = null;
    if (items.isEmpty && currentStep.value > productsStep) {
      currentStep.value = productsStep;
    }
  }

  bool setLineQuantity(String lineKey, int quantity) {
    final index = items.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return false;
    }

    return _setItemQuantityAt(index, quantity);
  }

  int quantityForProduct(int? productId) {
    if (productId == null) {
      return 0;
    }

    return items
        .where((item) => item.productId == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  int quantityForLine(int? productId, {int? productVariantId}) {
    final index = _indexOfLine(productId, productVariantId);
    if (index == -1) {
      return 0;
    }

    return items[index].quantity;
  }

  bool containsProduct(int? productId) => quantityForProduct(productId) > 0;

  bool _setItemQuantityAt(int index, int quantity) {
    final currentItem = items[index];
    if (quantity <= 0) {
      removeItem(currentItem.lineKey);
      return true;
    }

    final currentStock = currentItem.availableStock;
    if (currentStock != null && currentStock <= 0) {
      errorMessage.value =
          '${currentItem.variantLabel ?? currentItem.product.name ?? 'This product'} is currently unavailable.';
      return false;
    }

    items[index] = currentItem.copyWith(quantity: quantity);
    items.refresh();
    _markDraftDirty();
    errorMessage.value = null;
    return true;
  }

  bool get hasCustomerSelected => selectedCustomer.value?.id != null;
  bool get hasItems => items.isNotEmpty;
  bool get hasSavedDraft => savedDraftOrder.value?.id != null;
  bool get isDiscountEnabled => discountType.value != null;
  bool get hasKnownStockIssues =>
      items.any((item) => item.exceedsAvailableStock || item.isOutOfStock);
  bool get canSaveDraft =>
      !isSubmitting.value &&
      selectedCustomer.value?.id != null &&
      items.isNotEmpty;
  bool get canConfirm =>
      canSaveDraft &&
      !hasKnownStockIssues &&
      (savedDraftOrder.value?.status ?? 'draft') != 'confirmed';
  bool get showFooterTotals => currentStep.value != customerStep && hasItems;
  bool get isExistingDraft => savedDraftOrder.value?.status == 'draft';
  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);
  num get subtotal =>
      _normalizeMoney(items.fold<num>(0, (sum, item) => sum + item.lineTotal));
  num get displaySubtotal => _canUseSavedDraftTotals
      ? (savedDraftOrder.value?.subtotal ?? subtotal)
      : subtotal;
  num get displayDiscountAmount => _canUseSavedDraftTotals
      ? (savedDraftOrder.value?.discountAmount ?? estimatedDiscountAmount)
      : estimatedDiscountAmount;
  num get displayGrandTotal => _canUseSavedDraftTotals
      ? (savedDraftOrder.value?.grandTotal ?? grandTotal)
      : grandTotal;

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

  String? get stockWarningSummary {
    final unavailableCount = items.where((item) => item.isOutOfStock).length;
    final exceededCount = items
        .where((item) => item.exceedsAvailableStock)
        .length;

    if (unavailableCount == 0 && exceededCount == 0) {
      return null;
    }

    if (unavailableCount > 0 && exceededCount > 0) {
      return '$unavailableCount item(s) are unavailable and $exceededCount line(s) exceed current stock.';
    }

    if (unavailableCount > 0) {
      return '$unavailableCount item(s) are currently unavailable.';
    }

    return '$exceededCount line(s) exceed current stock. You can still save the draft, but confirm stays disabled until the quantities are fixed.';
  }

  bool get canContinueCurrentStep {
    switch (currentStep.value) {
      case customerStep:
        return hasCustomerSelected;
      case productsStep:
        return hasItems;
      case cartStep:
        return hasItems;
      default:
        return canSaveDraft;
    }
  }

  bool canGoToStep(int step) {
    return step >= customerStep && step <= confirmStep;
  }

  bool canOpenStep(int step) {
    if (!canGoToStep(step)) {
      return false;
    }

    for (var index = customerStep; index < step; index++) {
      if (validationMessageForStep(index) != null) {
        return false;
      }
    }

    return true;
  }

  void clearCart() {
    items.clear();
    selectedCustomer.value = null;
    currentStep.value = customerStep;
    discountType.value = null;
    discountValue.value = null;
    noteText.value = '';
    selectedOrderDate.value = DateTime.now();
    savedDraftOrder.value = null;
    hasUnsavedDraftChanges.value = false;
    errorMessage.value = null;
    infoMessage.value = null;
    noteController.clear();
    discountValueController.clear();
  }

  void startNewOrder() {
    clearCart();
    currentStep.value = customerStep;
  }

  void setSelectedCustomer(CustomerModel? customer) {
    selectedCustomer.value = customer;
    _markDraftDirty();
    errorMessage.value = null;
  }

  void nextStep() {
    final validationMessage = validationMessageForStep(currentStep.value);
    if (validationMessage != null) {
      errorMessage.value = validationMessage;
      return;
    }

    errorMessage.value = null;
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

    final currentStepValidation = validationMessageForStep(currentStep.value);
    if (step > currentStep.value && currentStepValidation != null) {
      errorMessage.value = currentStepValidation;
      return;
    }

    if (step > currentStep.value && !canOpenStep(step)) {
      final blockingMessage = validationMessageForStep(step - 1);
      if (blockingMessage != null) {
        errorMessage.value = blockingMessage;
      }
      return;
    }

    errorMessage.value = null;
    currentStep.value = step;
  }

  void setDiscountType(String? value) {
    if (value == null || value == 'none') {
      discountType.value = null;
      discountValue.value = null;
      discountValueController.clear();
      _markDraftDirty();
      return;
    }

    discountType.value = _isPercentageDiscount(value) ? 'percentage' : value;
    if (discountValueController.text.trim().isNotEmpty) {
      _syncDiscountValue();
    }
    _markDraftDirty();
  }

  void onDiscountValueChanged(String value) {
    discountValue.value = _parseDiscountValue(value.trim());
    _markDraftDirty();
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

  String? validationMessageForStep(int step) {
    if (step == customerStep && !hasCustomerSelected) {
      return 'Please select a customer.';
    }

    if (step == productsStep && !hasItems) {
      return 'Please add at least one product.';
    }

    if (step == cartStep && !hasItems) {
      return 'Your cart is empty. Add products to continue.';
    }

    return null;
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '৳0.00';
    }

    return '৳${_normalizeMoney(value).toStringAsFixed(2)}';
  }

  Future<CreateOrderResponseModel?> saveDraft() async {
    if (selectedCustomer.value?.id == null) {
      errorMessage.value = 'Select a customer before saving the draft.';
      return null;
    }

    if (items.isEmpty) {
      errorMessage.value = 'Add at least one product before saving the draft.';
      return null;
    }

    errorMessage.value = null;
    infoMessage.value = null;
    isSubmitting.value = true;

    try {
      final request = _buildDraftRequest();
      final orderId = savedDraftOrder.value?.id;
      final response = orderId == null
          ? await _orderRepository.createOrder(request)
          : await _orderRepository.updateOrderDraft(orderId, request);

      if (response.data != null) {
        savedDraftOrder.value = response.data;
        hasUnsavedDraftChanges.value = false;
        infoMessage.value = response.data?.status == 'draft'
            ? 'Draft saved. You can keep editing before confirming.'
            : response.message;
      }

      return response;
    } on ApiException catch (error) {
      errorMessage.value = _formatApiException(error);
    } catch (_) {
      errorMessage.value = 'Unable to save the draft right now.';
    } finally {
      isSubmitting.value = false;
    }

    return null;
  }

  Future<CreateOrderResponseModel?> confirmOrder() async {
    if (selectedCustomer.value?.id == null) {
      errorMessage.value = 'Select a customer before confirming the order.';
      return null;
    }

    if (items.isEmpty) {
      errorMessage.value = 'Add at least one product before confirming.';
      return null;
    }

    if (hasKnownStockIssues) {
      errorMessage.value =
          stockWarningSummary ??
          'Resolve the stock warnings before confirming the order.';
      return null;
    }

    errorMessage.value = null;
    infoMessage.value = null;
    isSubmitting.value = true;

    try {
      var orderId = savedDraftOrder.value?.id;
      if (orderId == null || hasUnsavedDraftChanges.value) {
        final request = _buildDraftRequest();
        final draftResponse = orderId == null
            ? await _orderRepository.createOrder(request)
            : await _orderRepository.updateOrderDraft(orderId, request);
        orderId = draftResponse.data?.id;
        if (orderId == null) {
          errorMessage.value =
              draftResponse.message ??
              'Unable to save the draft before confirm.';
          return null;
        }
        savedDraftOrder.value = draftResponse.data;
        hasUnsavedDraftChanges.value = false;
      }

      final response = await _orderRepository.confirmOrder(orderId);
      if (response.data != null) {
        savedDraftOrder.value = response.data;
        hasUnsavedDraftChanges.value = false;
      }

      clearCart();
      return response;
    } on ApiException catch (error) {
      errorMessage.value = _formatApiException(error);
    } catch (_) {
      errorMessage.value = 'Unable to confirm the order right now.';
    } finally {
      isSubmitting.value = false;
    }

    return null;
  }

  Future<CreateOrderResponseModel?> submitOrder() => confirmOrder();

  Future<bool> deleteDraft({int? orderId}) async {
    final targetOrderId = orderId ?? savedDraftOrder.value?.id;
    if (targetOrderId == null) {
      clearCart();
      return true;
    }

    isSubmitting.value = true;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      await _orderRepository.deleteOrder(targetOrderId);
      if (savedDraftOrder.value?.id == targetOrderId) {
        clearCart();
      }
      return true;
    } on ApiException catch (error) {
      errorMessage.value = _formatApiException(error);
    } catch (_) {
      errorMessage.value = 'Unable to delete the draft right now.';
    } finally {
      isSubmitting.value = false;
    }

    return false;
  }

  Future<void> hydrateDraftFromOrder(OrderModel order) async {
    final orderId = order.id;
    if (orderId == null) {
      errorMessage.value = 'Draft order details are missing.';
      return;
    }

    isHydratingDraft.value = true;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      final draftOrder = await _loadOrderForEditing(orderId, fallback: order);
      final draftItems = <CartItemModel>[];

      for (final item in draftOrder.items ?? const <OrderItemModel>[]) {
        final productId = item.productId;
        if (productId == null) {
          continue;
        }

        try {
          final productDetails = await _productRepository.fetchProductDetails(
            productId,
            forceRefresh: true,
          );
          final product = productDetails.data;
          if (product == null) {
            throw ApiException(message: 'Product details were not returned.');
          }

          ProductVariantModel? variant;
          if (item.productVariantId != null) {
            variant = (product.variants ?? const <ProductVariantModel>[])
                .cast<ProductVariantModel?>()
                .firstWhere(
                  (candidate) => candidate?.id == item.productVariantId,
                  orElse: () => null,
                );
          }

          draftItems.add(
            CartItemModel(
              product: product,
              quantity: item.quantity ?? 1,
              variant: variant,
            ),
          );
        } catch (_) {
          draftItems.add(_fallbackCartItem(item));
        }
      }

      items.assignAll(draftItems);
      selectedCustomer.value = CustomerModel(
        id: draftOrder.customer?.id,
        name: draftOrder.customer?.name,
        phone: draftOrder.customer?.phone,
      );
      noteText.value = draftOrder.note ?? '';
      noteController.text = noteText.value;
      discountType.value = draftOrder.discountType;
      discountValue.value = draftOrder.discountValue;
      discountValueController.text = draftOrder.discountValue == null
          ? ''
          : _normalizeMoney(draftOrder.discountValue!).toStringAsFixed(2);
      selectedOrderDate.value =
          DateTime.tryParse((draftOrder.orderDate ?? '').split('T').first) ??
          DateTime.now();
      savedDraftOrder.value = draftOrder;
      hasUnsavedDraftChanges.value = false;
      currentStep.value = confirmStep;
      infoMessage.value =
          'Draft ${draftOrder.orderNo ?? ''} loaded. You can edit, save, and confirm it from here.'
              .trim();
    } on ApiException catch (error) {
      errorMessage.value = _formatApiException(error);
    } catch (_) {
      errorMessage.value = 'Unable to open the draft for editing right now.';
    } finally {
      isHydratingDraft.value = false;
    }
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
        return 'Confirm Order';
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _syncNoteText() {
    noteText.value = noteController.text;
    _markDraftDirty();
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

  bool get _canUseSavedDraftTotals =>
      savedDraftOrder.value != null && !hasUnsavedDraftChanges.value;

  CreateOrderRequestModel _buildDraftRequest() {
    return CreateOrderRequestModel(
      customerId: selectedCustomer.value?.id,
      orderDate: _formatDate(selectedOrderDate.value),
      note: noteText.value.trim().isEmpty ? null : noteText.value.trim(),
      discountType: apiDiscountType,
      discountValue: appliedDiscountValue,
      items: items
          .where((item) => item.productId != null)
          .map(
            (item) => OrderItemRequestModel(
              productId: item.productId,
              productVariantId: item.productVariantId,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );
  }

  void _markDraftDirty() {
    if (savedDraftOrder.value == null && items.isEmpty) {
      hasUnsavedDraftChanges.value = false;
      return;
    }

    hasUnsavedDraftChanges.value = true;
    infoMessage.value = null;
  }

  String _formatApiException(ApiException error) {
    final validationErrors = error.errors;
    if (validationErrors != null && validationErrors.isNotEmpty) {
      final messages = <String>[];
      for (final value in validationErrors.values) {
        if (value is List) {
          messages.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return error.message;
  }

  Future<OrderModel> _loadOrderForEditing(
    int orderId, {
    required OrderModel fallback,
  }) async {
    try {
      final response = await _orderRepository.fetchOrderDetails(orderId);
      return response.data ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  CartItemModel _fallbackCartItem(OrderItemModel item) {
    final product = ProductModel(
      id: item.productId,
      name: item.productName ?? 'Unnamed product',
      hasVariants: item.productVariantId != null,
      sellingPrice: item.unitPrice,
      currentStock: item.quantity,
    );
    final variant = item.productVariantId == null
        ? null
        : ProductVariantModel(
            id: item.productVariantId,
            combinationLabel: item.variantLabel,
            sellingPrice: item.unitPrice,
            currentStock: item.quantity,
          );

    return CartItemModel(
      product: product,
      quantity: item.quantity ?? 1,
      variant: variant,
    );
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
