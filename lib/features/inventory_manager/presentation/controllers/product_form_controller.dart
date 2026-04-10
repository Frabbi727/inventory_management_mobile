import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import '../../data/models/create_or_update_barcode_product_request.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/product_form_args.dart';
import '../models/selected_product_photo.dart';
import '../services/product_photo_compression_service.dart';

class ProductFormController extends GetxController {
  ProductFormController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;
  final formKey = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final compressionService = const ProductPhotoCompressionService();

  late final ProductFormArgs args;
  late final TextEditingController nameController;
  late final TextEditingController skuController;
  late final TextEditingController barcodeController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController sellingPriceController;
  late final TextEditingController minimumStockController;

  final categories = <CategoryModel>[].obs;
  final units = <ProductUnitModel>[].obs;
  final selectedPhotos = <SelectedProductPhoto>[].obs;
  final isSubmitting = false.obs;
  final isReferenceDataLoading = false.obs;
  final errorMessage = RxnString();
  final photoErrorMessage = RxnString();
  final selectedCategoryId = RxnInt();
  final selectedUnitId = RxnInt();
  final selectedStatus = 'active'.obs;

  int _nextPhotoId = 0;

  bool get isEdit => args.mode == ProductFormMode.edit;
  bool get hasPendingCompression =>
      selectedPhotos.any((photo) => photo.isCompressing);

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    args = argument is ProductFormArgs
        ? argument
        : const ProductFormArgs.create();
    nameController = TextEditingController(text: args.name ?? '');
    skuController = TextEditingController(text: args.sku ?? '');
    barcodeController = TextEditingController(text: args.barcode ?? '');
    purchasePriceController = TextEditingController(
      text: args.purchasePrice?.toString() ?? '',
    );
    sellingPriceController = TextEditingController(
      text: args.sellingPrice?.toString() ?? '',
    );
    minimumStockController = TextEditingController(
      text: args.minimumStockAlert?.toString() ?? '',
    );
    selectedCategoryId.value = args.categoryId;
    selectedUnitId.value = args.unitId;
    selectedStatus.value = args.status ?? 'active';
    loadReferenceData();
  }

  @override
  void onClose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    minimumStockController.dispose();
    super.onClose();
  }

  Future<void> loadReferenceData() async {
    isReferenceDataLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait<dynamic>([
        _inventoryManagerRepository.fetchCategories(),
        _inventoryManagerRepository.fetchUnits(),
      ]);
      final fetchedCategories = results[0] as List<CategoryModel>;
      final fetchedUnits = results[1] as List<ProductUnitModel>;

      categories.assignAll(fetchedCategories);
      units.assignAll(fetchedUnits);
      selectedCategoryId.value ??= categories.isNotEmpty
          ? categories.first.id
          : null;
      selectedUnitId.value ??= units.isNotEmpty ? units.first.id : null;
    } catch (_) {
      errorMessage.value = 'Unable to load categories right now.';
    } finally {
      isReferenceDataLoading.value = false;
    }
  }

  void onCategoryChanged(int? value) {
    selectedCategoryId.value = value;
  }

  void onUnitChanged(int? value) {
    selectedUnitId.value = value;
  }

  void onStatusChanged(String? value) {
    if (value != null) {
      selectedStatus.value = value;
    }
  }

  Future<void> submit() async {
    final currentState = formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    final categoryId = selectedCategoryId.value;
    final unitId = selectedUnitId.value;
    if (categoryId == null) {
      errorMessage.value = 'Category is required.';
      return;
    }
    if (unitId == null) {
      errorMessage.value = 'Unit is required.';
      return;
    }

    final request = CreateOrUpdateBarcodeProductRequest(
      name: nameController.text.trim(),
      sku: "",
      barcode: barcodeController.text.trim(),
      categoryId: categoryId,
      unitId: unitId,
      purchasePrice: num.parse(purchasePriceController.text.trim()),
      sellingPrice: num.parse(sellingPriceController.text.trim()),
      minimumStockAlert: int.parse(minimumStockController.text.trim()),
      status: selectedStatus.value,
    );

    isSubmitting.value = true;
    errorMessage.value = null;
    photoErrorMessage.value = null;

    try {
      final readyPhotos = selectedPhotos
          .where((photo) => photo.isReady && photo.uploadFile != null)
          .map((photo) => photo.uploadFile!)
          .toList();

      final product = isEdit
          ? await _inventoryManagerRepository.updateProductByBarcode(
              args.barcode ?? '',
              request,
              photos: readyPhotos,
            )
          : await _inventoryManagerRepository.createProductFromBarcode(
              request,
              photos: readyPhotos,
            );

      Get.offNamed(AppRoutes.productDetails, arguments: product);
      Get.snackbar(
        'Product saved',
        isEdit
            ? 'Product updated successfully.'
            : 'Product created successfully.',
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      photoErrorMessage.value = _extractPhotoError(error);
    } catch (_) {
      errorMessage.value = 'Unable to save the product right now.';
    } finally {
      isSubmitting.value = false;
    }
  }

  String get _resolvedSku {
    final value = skuController.text.trim();
    if (value.isNotEmpty) {
      return value;
    }

    final barcode = barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      return 'SKU-$barcode';
    }

    return 'AUTO-${DateTime.now().millisecondsSinceEpoch}';
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? requiredNumberField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    if (num.tryParse(value.trim()) == null) {
      return 'Enter a valid number.';
    }
    return null;
  }

  Future<void> pickFromGallery() async {
    try {
      final files = await imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );
      if (files.isEmpty) {
        return;
      }
      await _addPhotos(files, ProductPhotoSource.gallery);
    } on PlatformException catch (error) {
      _showPhotoPickerError(_mapPickerError(error));
    } catch (_) {
      _showPhotoPickerError('Unable to open the gallery right now.');
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final file = await imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      await _addPhotos(<XFile>[file], ProductPhotoSource.camera);
    } on PlatformException catch (error) {
      _showPhotoPickerError(_mapPickerError(error));
    } catch (_) {
      _showPhotoPickerError('Unable to open the camera right now.');
    }
  }

  void removePhoto(String id) {
    selectedPhotos.removeWhere((photo) => photo.id == id);
  }

  String photoStatusLabel(SelectedProductPhotoStatus status) {
    return switch (status) {
      SelectedProductPhotoStatus.ready => 'Ready',
      SelectedProductPhotoStatus.compressing => 'Compressing',
      SelectedProductPhotoStatus.tooLarge => 'Too large',
      SelectedProductPhotoStatus.failed => 'Failed',
    };
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kiloBytes = bytes / 1024;
    return '${kiloBytes.toStringAsFixed(kiloBytes >= 100 ? 0 : 1)} KB';
  }

  Future<void> _addPhotos(List<XFile> files, ProductPhotoSource source) async {
    final pendingPhotos = files
        .map((file) => (file: file, id: _createPhotoId()))
        .toList();

    photoErrorMessage.value = null;
    selectedPhotos.addAll(
      pendingPhotos.map(
        (pendingPhoto) => SelectedProductPhoto(
          id: pendingPhoto.id,
          path: pendingPhoto.file.path,
          fileName: pendingPhoto.file.name,
          source: source,
          originalBytes: 0,
          status: SelectedProductPhotoStatus.compressing,
        ),
      ),
    );

    for (final pendingPhoto in pendingPhotos) {
      final file = pendingPhoto.file;
      final id = pendingPhoto.id;
      try {
        final originalBytes = await File(file.path).length();
        _updatePhoto(
          id,
          (photo) => photo.copyWith(originalBytes: originalBytes),
        );
        final result = await compressionService.compress(file);
        _updatePhoto(
          id,
          (photo) => photo.copyWith(
            compressedBytes: result.compressedBytes,
            status: result.status,
            uploadFile: result.file,
            clearUploadFile: result.file == null,
            errorMessage: result.errorMessage,
            clearErrorMessage: result.errorMessage == null,
          ),
        );
      } catch (_) {
        _updatePhoto(
          id,
          (photo) => photo.copyWith(
            status: SelectedProductPhotoStatus.failed,
            clearUploadFile: true,
            errorMessage: 'Compression failed for this image.',
          ),
        );
      }
    }
  }

  void _updatePhoto(
    String id,
    SelectedProductPhoto Function(SelectedProductPhoto photo) update,
  ) {
    final index = selectedPhotos.indexWhere((photo) => photo.id == id);
    if (index == -1) {
      return;
    }

    selectedPhotos[index] = update(selectedPhotos[index]);
    selectedPhotos.refresh();
  }

  String _createPhotoId() => 'photo-${_nextPhotoId++}';

  void _showPhotoPickerError(String message) {
    photoErrorMessage.value = message;
  }

  String _mapPickerError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('camera_access_denied') ||
        code.contains('camera_access_restricted')) {
      return 'Camera access is required to take product photos. Allow permission and try again.';
    }
    if (code.contains('photo_access_denied') ||
        code.contains('photo_access_restricted')) {
      return 'Gallery access is required to choose product photos. Allow permission and try again.';
    }
    if (code.contains('no_available_camera')) {
      return 'No camera is available on this device.';
    }
    if (code.contains('already_active') || code.contains('multiple_request')) {
      return 'Another photo picker request is already in progress. Close it and try again.';
    }
    if (code.contains('invalid_image')) {
      return 'The selected image could not be read. Try another photo.';
    }
    if (code.contains('permission') || message.contains('permission')) {
      return 'Photo permission is blocked for this app. Enable camera or photo access in system settings and try again.';
    }

    const fallback = 'Unable to open photo access right now. Please try again.';
    if (!kDebugMode) {
      return fallback;
    }

    final details = <String>[
      'code=${error.code}',
      if (error.message != null && error.message!.trim().isNotEmpty)
        'message=${error.message!.trim()}',
    ].join(', ');
    return '$fallback ($details)';
  }

  String? _extractPhotoError(ApiException error) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return null;
    }

    for (final entry in errors.entries) {
      if (!entry.key.startsWith('photos')) {
        continue;
      }

      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
