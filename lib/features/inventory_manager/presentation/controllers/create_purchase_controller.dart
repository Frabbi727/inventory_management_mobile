import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/barcode_scan_models.dart';
import '../models/product_form_args.dart';
import '../models/purchase_draft_item.dart';
import '../models/purchase_line_editor_args.dart';
import 'inventory_product_catalog_controller.dart';

class CreatePurchaseController extends InventoryProductCatalogController {
  CreatePurchaseController({
    required super.productRepository,
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository,
       super();

  final InventoryManagerRepository _inventoryManagerRepository;

  final isResolvingBarcode = false.obs;
  final isSubmitting = false.obs;
  final purchaseDate = DateTime.now().obs;
  final draftItems = <PurchaseDraftItem>[].obs;
  final noteController = TextEditingController();
  final submitError = RxnString();

  @override
  bool get loadCategoriesOnInit => true;

  double get totalAmount =>
      draftItems.fold(0, (sum, item) => sum + item.totalAmount);

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  @override
  String buildEmptyMessage(
    String query,
    int? categoryId,
    int? subcategoryId,
    ProductStockStatus? stockStatus,
  ) {
    return 'No products found for the current search and category filters.';
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

  String formatCurrency(num value) => '৳${value.toStringAsFixed(2)}';

  Future<void> openScanner() async {
    if (isResolvingBarcode.value) {
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.purchaseLookup,
      ),
    );

    if (result is! BarcodeScanResult) {
      return;
    }

    isResolvingBarcode.value = true;
    try {
      final lookup = await _inventoryManagerRepository
          .getPurchaseProductByBarcode(result.barcode);
      final product = lookup.data;
      if (product?.id == null) {
        _showProductNotFoundDialog(result.barcode);
        return;
      }

      await openPurchaseDetails(product!);
    } catch (_) {
      Get.snackbar(
        'Unable to resolve barcode',
        'The barcode could not be matched right now. Please try again.',
      );
    } finally {
      isResolvingBarcode.value = false;
    }
  }

  Future<void> openPurchaseDetails(ProductModel product) async {
    final existingItem = _findDraftItem(product.id, product.matchedVariant?.id);
    final result = await Get.toNamed(
      AppRoutes.inventoryPurchaseDetails,
      arguments: PurchaseLineEditorArgs(
        product: product,
        initialItem: existingItem,
      ),
    );

    if (result is PurchaseDraftItem) {
      _upsertDraftItem(result);
    }
  }

  Future<void> openDraftItemEditor(PurchaseDraftItem item) async {
    final product = item.product;
    if (product == null) {
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.inventoryPurchaseDetails,
      arguments: PurchaseLineEditorArgs(product: product, initialItem: item),
    );

    if (result is PurchaseDraftItem) {
      if (result.lineKey != item.lineKey) {
        draftItems.removeWhere((existing) => existing.lineKey == item.lineKey);
      }
      _upsertDraftItem(result);
    }
  }

  void removeDraftItem(String lineKey) {
    draftItems.removeWhere((item) => item.lineKey == lineKey);
    submitError.value = null;
  }

  Future<void> submitPurchase() async {
    if (draftItems.isEmpty) {
      submitError.value = 'Add at least one purchase item before saving.';
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

      await _openCreatedPurchase(response);
    } on ApiException catch (error) {
      submitError.value = _buildPurchaseError(error);
    } catch (_) {
      submitError.value = 'Unable to save the purchase right now.';
    } finally {
      isSubmitting.value = false;
    }
  }

  void openCreateProduct(String barcode) {
    Get.toNamed(
      AppRoutes.inventoryProductForm,
      arguments: ProductFormArgs.create(
        barcode: barcode,
        source: ProductFormSource.scan,
      ),
    );
  }

  PurchaseDraftItem? _findDraftItem(int? productId, int? productVariantId) {
    if (productId == null) {
      return null;
    }

    return draftItems.firstWhereOrNull(
      (item) =>
          item.productId == productId &&
          item.productVariantId == productVariantId,
    );
  }

  void _upsertDraftItem(PurchaseDraftItem item) {
    final exactIndex = draftItems.indexWhere(
      (existing) => existing.lineKey == item.lineKey,
    );
    if (exactIndex != -1) {
      draftItems[exactIndex] = item;
      draftItems.refresh();
      submitError.value = null;
      return;
    }

    final duplicateIndex = draftItems.indexWhere(
      (existing) =>
          existing.productId == item.productId &&
          existing.productVariantId == item.productVariantId,
    );
    if (duplicateIndex != -1) {
      draftItems[duplicateIndex] = item;
      draftItems.refresh();
      submitError.value = null;
      Get.snackbar(
        'Line updated',
        'The existing product line was updated instead of creating a duplicate.',
      );
      return;
    }

    draftItems.add(item);
    submitError.value = null;
  }

  Future<void> _openCreatedPurchase(PurchaseResponseModel response) async {
    final purchaseId = response.id;
    if (purchaseId == null) {
      Get.back(result: true);
      Get.snackbar('Purchase created', 'Purchase saved successfully.');
      return;
    }

    Get.back(result: true);
    await Future<void>.delayed(Duration.zero);
    await Get.toNamed(AppRoutes.inventoryPurchaseView, arguments: purchaseId);
    Get.snackbar(
      'Purchase created',
      response.purchaseNo?.isNotEmpty == true
          ? 'Purchase ${response.purchaseNo} saved successfully.'
          : 'Purchase saved successfully.',
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

  void _showProductNotFoundDialog(String barcode) {
    Get.dialog(
      AlertDialog(
        title: const Text('Product not found'),
        content: Text(
          'No existing product matched "$barcode". You can create a new product or return to the list.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Back')),
          FilledButton(
            onPressed: () {
              Get.back();
              openCreateProduct(barcode);
            },
            child: const Text('Create Product'),
          ),
        ],
      ),
    );
  }
}
