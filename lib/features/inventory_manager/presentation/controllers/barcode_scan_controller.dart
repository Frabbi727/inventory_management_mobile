import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/models/barcode_resolve_response.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/barcode_scan_models.dart';
import '../models/product_form_args.dart';
import '../../../products/data/repositories/product_repository.dart';

class BarcodeScanController extends GetxController {
  BarcodeScanController({
    required InventoryManagerRepository inventoryManagerRepository,
    required ProductRepository productRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository,
       _productRepository = productRepository;

  final InventoryManagerRepository _inventoryManagerRepository;
  final ProductRepository _productRepository;

  final barcodeController = TextEditingController();
  final scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final isResolving = false.obs;
  final hasDetectedBarcode = false.obs;
  final errorMessage = RxnString();
  final scanContext = BarcodeScanContext.productLookup.obs;

  String get subtitle => scanContext.value == BarcodeScanContext.purchaseLookup
      ? 'Scan a barcode to add a product to the purchase draft.'
      : scanContext.value == BarcodeScanContext.salesOrderLookup
      ? 'Scan a barcode to find a product and add it to the sales order.'
      : 'Scan a barcode to open an existing product or create a new one.';

  String get title => scanContext.value == BarcodeScanContext.purchaseLookup
      ? 'Scan Purchase Item'
      : scanContext.value == BarcodeScanContext.salesOrderLookup
      ? 'Scan Product'
      : 'Scan Barcode';

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is BarcodeScanArgs) {
      scanContext.value = argument.context;
    }
  }

  @override
  void onClose() {
    barcodeController.dispose();
    scannerController.dispose();
    super.onClose();
  }

  Future<void> handleDetection(BarcodeCapture capture) async {
    if (hasDetectedBarcode.value || isResolving.value) {
      return;
    }

    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    if (value.isEmpty) {
      return;
    }

    barcodeController.text = value;
    await resolveBarcode(value, fromCamera: true);
  }

  Future<void> resolveBarcode(
    String rawBarcode, {
    bool fromCamera = false,
  }) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) {
      errorMessage.value = 'Enter a barcode before continuing.';
      return;
    }

    isResolving.value = true;
    errorMessage.value = null;
    if (fromCamera) {
      hasDetectedBarcode.value = true;
    }

    await scannerController.stop();

    try {
      if (scanContext.value == BarcodeScanContext.purchaseLookup) {
        Get.back(result: BarcodeScanResult(barcode: barcode));
        return;
      }

      if (scanContext.value == BarcodeScanContext.salesOrderLookup) {
        final product = await _productRepository.fetchProductByBarcode(
          barcode,
        );
        Get.back(
          result: BarcodeScanResult(barcode: barcode, product: product),
        );
        return;
      }

      final response = await _inventoryManagerRepository.resolveProductBarcode(
        barcode,
      );
      await _handleProductLookupResponse(response);
    } catch (_) {
      errorMessage.value =
          'Unable to resolve this barcode right now. Try again or enter it manually.';
    } finally {
      isResolving.value = false;
    }
  }

  Future<void> resumeScanning() async {
    hasDetectedBarcode.value = false;
    errorMessage.value = null;
    await scannerController.start();
  }

  Future<void> _handleProductLookupResponse(
    BarcodeResolveResponse response,
  ) async {
    final action = response.action.trim().toLowerCase();
    final shouldCreate = action == 'create' || !response.exists;
    final shouldOpenExisting =
        action == 'view_or_update' || response.exists;

    if (shouldCreate) {
      await _openExistingProductIfAvailable(response.barcode);
      return;
    }

    if (!shouldOpenExisting) {
      errorMessage.value =
          'Unable to determine whether this barcode belongs to an existing product.';
      return;
    }

    final product = response.data;
    if (product?.id != null) {
      Get.offNamed(AppRoutes.productDetails, arguments: product!.id);
      return;
    }

    final opened = await _openExistingProductIfAvailable(
      response.barcode,
      showErrorOnFailure: true,
    );
    if (!opened) {
      errorMessage.value =
          'Product exists but details could not be loaded. Try again.';
    }
  }

  Future<bool> _openExistingProductIfAvailable(
    String barcode, {
    bool showErrorOnFailure = false,
  }) async {
    try {
      final fullProduct = await _inventoryManagerRepository.getProductByBarcode(
        barcode,
      );
      Get.offNamed(
        AppRoutes.productDetails,
        arguments: fullProduct.id ?? fullProduct,
      );
      return true;
    } catch (_) {
      if (showErrorOnFailure) {
        return false;
      }
    }

    if (!showErrorOnFailure) {
      Get.offNamed(
        AppRoutes.inventoryProductForm,
        arguments: ProductFormArgs.create(barcode: barcode),
      );
    }
    return false;
  }
}
