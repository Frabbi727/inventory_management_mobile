import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import 'purchase_list_controller.dart';
import 'purchase_records_controller.dart';
import '../models/purchase_draft_item.dart';

class EditPurchaseController extends GetxController {
  EditPurchaseController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final noteController = TextEditingController();
  final purchase = Rxn<PurchaseResponseModel>();
  final draftItems = <PurchaseDraftItem>[].obs;
  final _quantityControllers = <String, TextEditingController>{};
  final _unitCostControllers = <String, TextEditingController>{};
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
    _disposeItemControllers();
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
      draftItems.assignAll(_mapDraftItems(response));
      _rebuildItemControllers();

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
    _updateDraftItemValues(
      lineKey: original.lineKey,
      quantity: quantity,
      unitCost: unitCost,
    );
  }

  TextEditingController quantityControllerFor(String lineKey) =>
      _quantityControllers[lineKey]!;

  TextEditingController unitCostControllerFor(String lineKey) =>
      _unitCostControllers[lineKey]!;

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
                  productVariantId: item.productVariantId,
                  quantity: item.quantity,
                  unitCost: item.unitCost,
                ),
              )
              .toList(growable: false),
        ),
      );

      purchase.value = response;
      noteController.text = response.note ?? '';
      purchaseDate.value =
          DateTime.tryParse(response.purchaseDate ?? '') ?? purchaseDate.value;
      draftItems.assignAll(_mapDraftItems(response));
      _rebuildItemControllers();
      await _refreshPurchaseLists();
      _returnToPurchaseList();
      Get.snackbar('Success', 'Purchase updated successfully');
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

  String _buildPurchaseError(ApiException error) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return error.message;
    }

    final itemsError = errors['items'];
    if (itemsError is List && itemsError.isNotEmpty) {
      return itemsError.first.toString();
    }

    for (final key in [
      'purchase_date',
      'items.0.quantity',
      'items.0.unit_cost',
    ]) {
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

  List<PurchaseDraftItem> _mapDraftItems(PurchaseResponseModel response) {
    return (response.items ?? const [])
        .where((item) => item.productId != null)
        .map(
          (item) => PurchaseDraftItem(
            lineKey: _lineKeyFor(item.productId!, item.productVariantId),
            productId: item.productId!,
            productVariantId: item.productVariantId,
            variantLabel: item.variantLabel ?? item.product?.variant?.label,
            name: item.product?.name ?? item.productName ?? 'Unnamed product',
            sku: item.product?.sku ?? item.productBarcode ?? '-',
            barcode:
                item.product?.barcode ?? item.productBarcode ?? 'No barcode',
            quantity: (item.quantity ?? 0).toInt(),
            unitCost: (item.unitCost ?? 0).toDouble(),
            currentStock: item.product?.currentStock ?? 0,
            categoryName:
                item.product?.category?.name ?? 'Uncategorized product',
          ),
        )
        .toList(growable: false);
  }

  void _rebuildItemControllers() {
    _disposeItemControllers();
    for (final item in draftItems) {
      final quantityController = TextEditingController(
        text: '${item.quantity}',
      );
      quantityController.addListener(() {
        _updateDraftItemValues(
          lineKey: item.lineKey,
          quantity: int.tryParse(quantityController.text.trim()) ?? 0,
        );
      });

      final unitCostController = TextEditingController(
        text: item.unitCost.toStringAsFixed(2),
      );
      unitCostController.addListener(() {
        _updateDraftItemValues(
          lineKey: item.lineKey,
          unitCost: double.tryParse(unitCostController.text.trim()) ?? 0,
        );
      });

      _quantityControllers[item.lineKey] = quantityController;
      _unitCostControllers[item.lineKey] = unitCostController;
    }
  }

  void _disposeItemControllers() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _unitCostControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    _unitCostControllers.clear();
  }

  void _updateDraftItemValues({
    required String lineKey,
    int? quantity,
    double? unitCost,
  }) {
    final index = draftItems.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) {
      return;
    }

    final current = draftItems[index];
    final nextQuantity = quantity ?? current.quantity;
    final nextUnitCost = unitCost ?? current.unitCost;

    if (nextQuantity == current.quantity && nextUnitCost == current.unitCost) {
      return;
    }

    draftItems[index] = current.copyWith(
      quantity: nextQuantity,
      unitCost: nextUnitCost,
    );
    draftItems.refresh();
    submitError.value = null;
  }

  String _lineKeyFor(int productId, int? productVariantId) {
    return '$productId:${productVariantId ?? 'base'}';
  }

  Future<void> _refreshPurchaseLists() async {
    if (Get.isRegistered<PurchaseListController>()) {
      await Get.find<PurchaseListController>().fetchPurchases(reset: true);
    }
    if (Get.isRegistered<PurchaseRecordsController>()) {
      await Get.find<PurchaseRecordsController>().fetchPurchases(reset: true);
    }
  }

  void _returnToPurchaseList() {
    var foundTarget = false;

    Get.until((route) {
      final name = route.settings.name;
      final isTarget =
          name == AppRoutes.inventoryPurchases ||
          name == AppRoutes.inventoryHome;
      if (isTarget) {
        foundTarget = true;
      }
      return isTarget;
    });

    if (!foundTarget && (Get.key.currentState?.canPop() ?? false)) {
      Get.back(result: true);
    }
  }
}
