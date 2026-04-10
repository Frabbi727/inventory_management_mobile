import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class PurchaseDetailsController extends GetxController {
  PurchaseDetailsController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final quantityController = TextEditingController(text: '1');
  final unitCostController = TextEditingController();
  final noteController = TextEditingController();

  final product = Rxn<ProductModel>();
  final purchaseDate = DateTime.now().obs;
  final quantityError = RxnString();
  final unitCostError = RxnString();
  final submitError = RxnString();
  final isSubmitting = false.obs;

  int? get quantity => int.tryParse(quantityController.text.trim());
  double? get unitCost => double.tryParse(unitCostController.text.trim());
  double get totalAmount {
    final currentQuantity = quantity;
    final currentUnitCost = unitCost;
    if (currentQuantity == null || currentUnitCost == null) {
      return 0;
    }
    return currentQuantity * currentUnitCost;
  }

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is! ProductModel) {
      throw ArgumentError(
        'PurchaseDetailsPage requires a ProductModel argument.',
      );
    }

    product.value = argument;
    unitCostController.text = ((argument.purchasePrice ?? 0).toDouble())
        .toStringAsFixed(2);
    quantityController.addListener(_handleInputChange);
    unitCostController.addListener(_handleInputChange);
    noteController.addListener(_handleInputChange);
  }

  @override
  void onClose() {
    quantityController
      ..removeListener(_handleInputChange)
      ..dispose();
    unitCostController
      ..removeListener(_handleInputChange)
      ..dispose();
    noteController
      ..removeListener(_handleInputChange)
      ..dispose();
    super.onClose();
  }

  void decreaseQuantity() {
    final currentQuantity = quantity ?? 1;
    if (currentQuantity <= 1) {
      return;
    }
    quantityController.text = '${currentQuantity - 1}';
  }

  void increaseQuantity() {
    final currentQuantity = quantity ?? 0;
    quantityController.text = '${currentQuantity + 1}';
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      purchaseDate.value = picked;
    }
  }

  String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> submitPurchase() async {
    final currentProduct = product.value;
    if (currentProduct == null) {
      return;
    }

    final validation = _validate(currentProduct);
    if (!validation.isValid) {
      quantityError.value = validation.quantityError;
      unitCostError.value = validation.unitCostError;
      return;
    }

    isSubmitting.value = true;
    submitError.value = null;

    try {
      final response = await _inventoryManagerRepository.createPurchase(
        CreateOrUpdatePurchaseRequest(
          purchaseDate: formatDate(purchaseDate.value),
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
          items: [
            InventoryPurchaseItemRequest(
              productId: currentProduct.id!,
              quantity: validation.quantity!,
              unitCost: validation.unitCost!,
            ),
          ],
        ),
      );

      Get.back();
      Get.snackbar('Purchase created', buildPurchaseSavedMessage(response));
    } on ApiException catch (error) {
      submitError.value = _buildPurchaseError(error);
    } catch (_) {
      submitError.value = 'Unable to save the purchase right now.';
    } finally {
      isSubmitting.value = false;
    }
  }

  String buildPurchaseSavedMessage(PurchaseResponseModel response) {
    if (response.purchaseNo == null || response.purchaseNo!.isEmpty) {
      return 'Purchase saved successfully.';
    }

    return 'Purchase ${response.purchaseNo} saved successfully.';
  }

  PurchaseSubmissionValidation _validate(ProductModel product) {
    final parsedQuantity = int.tryParse(quantityController.text.trim());
    final parsedUnitCost = double.tryParse(unitCostController.text.trim());

    return PurchaseSubmissionValidation(
      quantity: parsedQuantity,
      unitCost: parsedUnitCost,
      quantityError: product.id == null
          ? 'Product could not be submitted.'
          : parsedQuantity == null || parsedQuantity <= 0
          ? 'Quantity must be greater than 0.'
          : null,
      unitCostError: parsedUnitCost == null || parsedUnitCost <= 0
          ? 'Unit cost must be greater than 0.'
          : null,
    );
  }

  String _buildPurchaseError(ApiException error) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return error.message;
    }

    final itemsError = errors['items'];
    if (itemsError is List && itemsError.isNotEmpty) {
      return itemsError.first.toString();
    }

    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return error.message;
  }

  void _handleInputChange() {
    quantityError.value = null;
    unitCostError.value = null;
    submitError.value = null;
  }
}

class PurchaseSubmissionValidation {
  const PurchaseSubmissionValidation({
    required this.quantity,
    required this.unitCost,
    required this.quantityError,
    required this.unitCostError,
  });

  final int? quantity;
  final double? unitCost;
  final String? quantityError;
  final String? unitCostError;

  bool get isValid => quantityError == null && unitCostError == null;
}
