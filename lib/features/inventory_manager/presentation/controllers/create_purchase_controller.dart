import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/barcode_scan_models.dart';
import '../models/product_form_args.dart';
import 'inventory_product_catalog_controller.dart';

class CreatePurchaseController extends InventoryProductCatalogController {
  CreatePurchaseController({
    required super.productRepository,
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository,
       super();

  final InventoryManagerRepository _inventoryManagerRepository;

  final isResolvingBarcode = false.obs;

  @override
  bool get loadCategoriesOnInit => true;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
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
      final product = await _inventoryManagerRepository
          .getPurchaseProductByBarcode(result.barcode);
      if (product.data?.id == null) {
        _showProductNotFoundDialog(result.barcode);
        return;
      }

      openPurchaseDetails(product.data!);
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
    final result = await Get.toNamed(
      AppRoutes.inventoryPurchaseDetails,
      arguments: product,
    );

    if (result is PurchaseResponseModel) {
      Get.back(result: result);
    }
  }

  void openCreateProduct(String barcode) {
    Get.toNamed(
      AppRoutes.inventoryProductForm,
      arguments: ProductFormArgs.create(barcode: barcode),
    );
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
