import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/purchase_draft_item.dart';

class EditPurchaseController extends GetxController {
  EditPurchaseController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final noteController = TextEditingController();
  final purchase = Rxn<PurchaseResponseModel>();
  final draftItems = <PurchaseDraftItem>[].obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final submitError = RxnString();
  final purchaseDate = DateTime.now().obs;

  late final int purchaseId;

  bool get hasEditableItems => draftItems.isNotEmpty;
  double get totalAmount =>
      draftItems.fold(0, (sum, item) => sum + item.totalAmount);

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is! int) {
      throw ArgumentError('EditPurchaseController requires a purchase id.');
    }

    purchaseId = argument;
    loadPurchase();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  Future<void> loadPurchase() async {
    isLoading.value = true;
    errorMessage.value = null;
    submitError.value = null;

    try {
      final response = await _inventoryManagerRepository.fetchPurchaseDetails(
        purchaseId,
      );
      purchase.value = response;
      noteController.text = response.note ?? '';
      purchaseDate.value =
          DateTime.tryParse(response.purchaseDate ?? '') ?? DateTime.now();
      draftItems.assignAll(
        (response.items ?? const [])
            .where((item) => item.productId != null)
            .map(
              (item) => PurchaseDraftItem(
                productId: item.productId!,
                name:
                    item.product?.name ??
                    item.productName ??
                    'Unnamed product',
                barcode:
                    item.product?.barcode ?? item.productBarcode ?? 'No barcode',
                quantity: (item.quantity ?? 0).toInt(),
                unitCost: (item.unitCost ?? 0).toDouble(),
                currentStock: item.product?.currentStock ?? 0,
                categoryName:
                    item.product?.category?.name ?? 'Uncategorized product',
              ),
            )
            .toList(growable: false),
      );

      if (draftItems.isEmpty) {
        errorMessage.value = 'This purchase has no editable items.';
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load purchase details right now.';
    } finally {
      isLoading.value = false;
    }
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

  void updateDraftItem({
    required PurchaseDraftItem original,
    required int quantity,
    required double unitCost,
  }) {
    final index = draftItems.indexWhere(
      (item) => item.productId == original.productId,
    );
    if (index == -1) {
      return;
    }

    draftItems[index] = original.copyWith(
      quantity: quantity,
      unitCost: unitCost,
    );
    draftItems.refresh();
    submitError.value = null;
  }

  Future<void> submitUpdate() async {
    if (draftItems.isEmpty) {
      submitError.value = 'Add at least one valid purchase item.';
      return;
    }

    final hasInvalidItem = draftItems.any(
      (item) => item.quantity <= 0 || item.unitCost < 0,
    );
    if (hasInvalidItem) {
      submitError.value =
          'Each purchase item must have quantity greater than 0 and unit cost of 0 or more.';
      return;
    }

    isSubmitting.value = true;
    submitError.value = null;

    try {
      final response = await _inventoryManagerRepository.updatePurchase(
        purchaseId,
        CreateOrUpdatePurchaseRequest(
          purchaseDate: formatDateForApi(purchaseDate.value),
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
          items: draftItems
              .map(
                (item) => InventoryPurchaseItemRequest(
                  productId: item.productId,
                  quantity: item.quantity,
                  unitCost: item.unitCost,
                ),
              )
              .toList(growable: false),
        ),
      );

      purchase.value = response;
      draftItems.assignAll(
        (response.items ?? const [])
            .where((item) => item.productId != null)
            .map(
              (item) => PurchaseDraftItem(
                productId: item.productId!,
                name:
                    item.product?.name ??
                    item.productName ??
                    'Unnamed product',
                barcode:
                    item.product?.barcode ?? item.productBarcode ?? 'No barcode',
                quantity: (item.quantity ?? 0).toInt(),
                unitCost: (item.unitCost ?? 0).toDouble(),
                currentStock: item.product?.currentStock ?? 0,
                categoryName:
                    item.product?.category?.name ?? 'Uncategorized product',
              ),
            )
            .toList(growable: false),
      );
      Get.back(result: true);
      Get.snackbar('Purchase updated', _buildSavedMessage(response));
    } on ApiException catch (error) {
      submitError.value = _buildPurchaseError(error);
    } catch (_) {
      submitError.value = 'Unable to update the purchase right now.';
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatDisplayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String formatDateForApi(DateTime date) => formatDisplayDate(date);

  String formatCurrency(num value) => '৳${value.toStringAsFixed(2)}';

  String _buildSavedMessage(PurchaseResponseModel response) {
    if (response.purchaseNo == null || response.purchaseNo!.isEmpty) {
      return 'Purchase updated successfully.';
    }

    return 'Purchase ${response.purchaseNo} updated successfully.';
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

    for (final key in ['purchase_date', 'items.0.quantity', 'items.0.unit_cost']) {
      final value = errors[key];
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
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
