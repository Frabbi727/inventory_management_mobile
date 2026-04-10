import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class PurchaseFlowController extends GetxController {
  PurchaseFlowController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final isResolvingBarcode = false.obs;
  final isSubmitting = false.obs;

  Future<ProductModel?> getPurchaseProductByBarcode(String barcode) async {
    isResolvingBarcode.value = true;
    try {
      final response = await _inventoryManagerRepository
          .getPurchaseProductByBarcode(barcode);
      return response.data;
    } finally {
      isResolvingBarcode.value = false;
    }
  }

  PurchaseSubmissionValidation validate({
    required ProductModel product,
    required String quantityText,
    required String unitCostText,
  }) {
    final quantity = int.tryParse(quantityText.trim());
    final unitCost = double.tryParse(unitCostText.trim());

    return PurchaseSubmissionValidation(
      quantity: quantity,
      unitCost: unitCost,
      quantityError: product.id == null
          ? 'Product could not be submitted.'
          : quantity == null || quantity <= 0
          ? 'Quantity must be greater than 0.'
          : null,
      unitCostError: unitCost == null || unitCost <= 0
          ? 'Unit cost must be greater than 0.'
          : null,
    );
  }

  Future<PurchaseSubmissionResult> submitPurchase({
    required ProductModel product,
    required DateTime purchaseDate,
    required String note,
    required String quantityText,
    required String unitCostText,
  }) async {
    final validation = validate(
      product: product,
      quantityText: quantityText,
      unitCostText: unitCostText,
    );
    if (!validation.isValid) {
      return PurchaseSubmissionResult.validation(validation);
    }

    isSubmitting.value = true;
    try {
      final response = await _inventoryManagerRepository.createPurchase(
        CreateOrUpdatePurchaseRequest(
          purchaseDate: formatDate(purchaseDate),
          note: note.trim().isEmpty ? null : note.trim(),
          items: [
            InventoryPurchaseItemRequest(
              productId: product.id!,
              quantity: validation.quantity!,
              unitCost: validation.unitCost!,
            ),
          ],
        ),
      );
      return PurchaseSubmissionResult.success(response);
    } on ApiException catch (error) {
      return PurchaseSubmissionResult.failure(_buildPurchaseError(error));
    } catch (_) {
      return const PurchaseSubmissionResult.failure(
        'Unable to save the purchase right now.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String buildPurchaseSavedMessage(PurchaseResponseModel response) {
    if (response.purchaseNo == null || response.purchaseNo!.isEmpty) {
      return 'Purchase saved successfully.';
    }

    return 'Purchase ${response.purchaseNo} saved successfully.';
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

class PurchaseSubmissionResult {
  const PurchaseSubmissionResult._({
    required this.response,
    required this.errorMessage,
    required this.validation,
  });

  const PurchaseSubmissionResult.success(PurchaseResponseModel response)
    : this._(response: response, errorMessage: null, validation: null);

  const PurchaseSubmissionResult.failure(String errorMessage)
    : this._(response: null, errorMessage: errorMessage, validation: null);

  const PurchaseSubmissionResult.validation(
    PurchaseSubmissionValidation validation,
  ) : this._(response: null, errorMessage: null, validation: validation);

  final PurchaseResponseModel? response;
  final String? errorMessage;
  final PurchaseSubmissionValidation? validation;

  bool get isSuccess => response != null;
}
