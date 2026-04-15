import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_subcategory_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import '../../../products/data/models/product_variant_attribute_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../data/models/create_or_update_barcode_product_request.dart';
import '../../data/models/product_photo_upload_file.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/editable_variant_attribute.dart';
import '../models/product_form_args.dart';
import '../models/selected_product_photo.dart';
import '../models/variant_combination_draft.dart';
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
  late final TextEditingController barcodeController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController sellingPriceController;
  late final TextEditingController minimumStockController;
  final _attributeNameControllers = <String, TextEditingController>{};
  final _attributeValuesControllers = <String, TextEditingController>{};
  final _attributeNameFocusNodes = <String, FocusNode>{};
  final _attributeValuesFocusNodes = <String, FocusNode>{};
  final _combinationQuantityControllers = <String, TextEditingController>{};
  final _combinationPurchasePriceControllers =
      <String, TextEditingController>{};
  final _combinationSellingPriceControllers = <String, TextEditingController>{};
  final _combinationStatusControllers = <String, String>{};

  final categories = <CategoryModel>[].obs;
  final subcategories = <ProductSubcategoryModel>[].obs;
  final units = <ProductUnitModel>[].obs;
  final selectedPhotos = <SelectedProductPhoto>[].obs;
  final variantAttributes = <EditableVariantAttribute>[].obs;
  final variantCombinations = <VariantCombinationDraft>[].obs;
  final isSubmitting = false.obs;
  final isReferenceDataLoading = false.obs;
  final isSubcategoryLoading = false.obs;
  final isVariantsEnabled = false.obs;
  final errorMessage = RxnString();
  final photoErrorMessage = RxnString();
  final subcategoryErrorMessage = RxnString();
  final variantErrorMessage = RxnString();
  final selectedCategoryId = RxnInt();
  final selectedSubcategoryId = RxnInt();
  final selectedUnitId = RxnInt();
  final selectedStatus = 'active'.obs;
  final expandedVariantKey = RxnString();

  int _nextPhotoId = 0;
  int _nextAttributeId = 0;
  int _nextVariantDraftId = 0;

  bool get isEdit => args.mode == ProductFormMode.edit;
  bool get isScanCreate => !isEdit && args.source == ProductFormSource.scan;
  bool get isManualCreate => !isEdit && args.source == ProductFormSource.manual;
  bool get hasPendingCompression =>
      selectedPhotos.any((photo) => photo.isCompressing);
  bool get showVariantSection => isVariantsEnabled.value;
  bool get showBasePriceFields => !isVariantsEnabled.value;
  bool get isSubcategoryEnabled =>
      !isSubcategoryLoading.value && selectedCategoryId.value != null;
  String get selectedUnitLabel {
    final unit = units.firstWhereOrNull(
      (item) => item.id == selectedUnitId.value,
    );
    if (unit == null) {
      return 'Unit not selected';
    }
    if (unit.shortName == null || unit.shortName!.trim().isEmpty) {
      return unit.name ?? 'Unit';
    }
    return '${unit.name ?? 'Unit'} (${unit.shortName!.trim()})';
  }

  int get variantAttributeCount => variantAttributes.length;
  int get variantCombinationCount => variantCombinations.length;
  bool get canGenerateVariantRows => variantAttributes.any((attribute) {
    final name =
        (_attributeNameControllers[attribute.id]?.text ?? attribute.name)
            .trim();
    final valuesText =
        (_attributeValuesControllers[attribute.id]?.text ??
                attributeValuesLabel(attribute))
            .trim();
    return name.isNotEmpty && valuesText.isNotEmpty;
  });
  bool get hasIncompleteVariantRows => variantAttributes.any(
    (attribute) =>
        attribute.name.trim().isEmpty ||
        attribute.values.every((value) => value.trim().isEmpty),
  );
  bool get hasDuplicateVariantNames {
    final names = variantAttributes
        .map((attribute) => attribute.name.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();
    return names.toSet().length != names.length;
  }

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    args = argument is ProductFormArgs
        ? argument
        : const ProductFormArgs.create();
    nameController = TextEditingController(text: args.name ?? '');
    barcodeController = TextEditingController(
      text: _resolveInitialBaseBarcode(),
    );
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
    selectedSubcategoryId.value = args.subcategoryId;
    selectedUnitId.value = args.unitId;
    selectedStatus.value = args.status ?? 'active';
    isVariantsEnabled.value = args.hasVariants ?? false;
    _seedVariantDrafts();
    loadReferenceData();
  }

  @override
  void onClose() {
    nameController.dispose();
    barcodeController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    minimumStockController.dispose();
    _disposeVariantControllers();
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

      await loadSubcategoriesForCategory(selectedCategoryId.value);
    } catch (_) {
      errorMessage.value = 'Unable to load product form data right now.';
    } finally {
      isReferenceDataLoading.value = false;
    }
  }

  Future<void> loadSubcategoriesForCategory(int? categoryId) async {
    subcategories.clear();
    subcategoryErrorMessage.value = null;
    if (categoryId == null) {
      selectedSubcategoryId.value = null;
      return;
    }

    isSubcategoryLoading.value = true;
    try {
      final fetchedSubcategories = await _inventoryManagerRepository
          .fetchSubcategories(categoryId: categoryId);
      subcategories.assignAll(fetchedSubcategories);
      final selectedId = selectedSubcategoryId.value;
      if (selectedId != null &&
          !fetchedSubcategories.any((item) => item.id == selectedId)) {
        selectedSubcategoryId.value = null;
      }
    } catch (_) {
      selectedSubcategoryId.value = null;
      subcategoryErrorMessage.value =
          'Unable to load subcategories for this category.';
    } finally {
      isSubcategoryLoading.value = false;
    }
  }

  Future<void> onCategoryChanged(int? value) async {
    if (selectedCategoryId.value == value) {
      return;
    }
    selectedCategoryId.value = value;
    selectedSubcategoryId.value = null;
    await loadSubcategoriesForCategory(value);
  }

  void onSubcategoryChanged(int? value) {
    selectedSubcategoryId.value = value;
  }

  void onUnitChanged(int? value) {
    selectedUnitId.value = value;
  }

  void onStatusChanged(String? value) {
    if (value != null) {
      selectedStatus.value = value;
    }
  }

  void onVariantsToggled(bool value) {
    isVariantsEnabled.value = value;
    variantErrorMessage.value = null;
    if (value) {
      if (variantCombinations.isEmpty) {
        addVariantRow();
      }
      return;
    }

    _disposeVariantControllers();
    variantAttributes.clear();
    variantCombinations.clear();
  }

  void addVariantRow() {
    final key = _createManualVariantKey();
    variantCombinations.add(
      VariantCombinationDraft(
        key: key,
        label: 'New Variant',
        attributes: const <String, String>{},
        quantity: 0,
        attributeNameDraft: '',
        attributeValueDraft: '',
      ),
    );
    variantCombinations.refresh();
    expandedVariantKey.value = key;
    _syncCombinationControllers();
    variantErrorMessage.value = null;
    update(['variant_rows']);
  }

  void removeVariantRow(String key) {
    variantCombinations.removeWhere((combination) => combination.key == key);
    variantCombinations.refresh();
    if (expandedVariantKey.value == key) {
      expandedVariantKey.value = variantCombinations.isEmpty
          ? null
          : variantCombinations.last.key;
    }
    _syncCombinationControllers();
    variantErrorMessage.value = null;
    update(['variant_rows']);
  }

  bool isVariantExpanded(String key) => expandedVariantKey.value == key;

  void toggleVariantExpanded(String key) {
    expandedVariantKey.value = expandedVariantKey.value == key ? null : key;
    update(['variant_rows']);
  }

  void addVariantAttribute() {
    final attribute = EditableVariantAttribute(
      id: 'attribute-${_nextAttributeId++}',
    );
    variantAttributes.add(attribute);
    _ensureAttributeControllers(attribute);
  }

  void removeVariantAttribute(String id) {
    _attributeNameControllers.remove(id)?.dispose();
    _attributeValuesControllers.remove(id)?.dispose();
    _attributeNameFocusNodes.remove(id)?.dispose();
    _attributeValuesFocusNodes.remove(id)?.dispose();
    variantAttributes.removeWhere((attribute) => attribute.id == id);
    _regenerateVariantCombinations();
  }

  void updateVariantAttributeName(String id, String value) {
    final index = variantAttributes.indexWhere(
      (attribute) => attribute.id == id,
    );
    if (index == -1) {
      return;
    }
    variantAttributes[index] = variantAttributes[index].copyWith(name: value);
    variantAttributes.refresh();
    variantErrorMessage.value = null;
    _regenerateVariantCombinations();
  }

  void updateVariantAttributeValues(String id, String rawValue) {
    final index = variantAttributes.indexWhere(
      (attribute) => attribute.id == id,
    );
    if (index == -1) {
      return;
    }
    final values = rawValue
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    variantAttributes[index] = variantAttributes[index].copyWith(
      values: values,
    );
    variantAttributes.refresh();
    variantErrorMessage.value = null;
    _regenerateVariantCombinations();
  }

  void generateVariantRows() {
    _syncAttributeDraftsFromControllers();
    _regenerateVariantCombinations(syncInputs: false);
    if (variantCombinations.isEmpty) {
      variantErrorMessage.value =
          'Add an attribute name and at least one value, then generate variant rows.';
      return;
    }
    variantErrorMessage.value = null;
  }

  String attributeValuesLabel(EditableVariantAttribute attribute) {
    if (attribute.values.isEmpty) {
      return '';
    }
    return attribute.values.join(', ');
  }

  void updateCombinationQuantity(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    if (!variantCombinations[index].isActive) {
      return;
    }
    final quantity = int.tryParse(rawValue.trim()) ?? 0;
    if (variantCombinations[index].quantity == (quantity < 0 ? 0 : quantity)) {
      return;
    }
    variantCombinations[index] = variantCombinations[index].copyWith(
      quantity: quantity < 0 ? 0 : quantity,
    );
    variantCombinations.refresh();
    variantErrorMessage.value = null;
  }

  void updateCombinationAttributeName(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    final current = variantCombinations[index];
    final currentValue = current.attributeValueDraft;
    _updateCombinationAttributes(
      index,
      current,
      attributeName: rawValue.trim(),
      attributeValue: currentValue,
    );
  }

  void updateCombinationAttributeValue(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    final current = variantCombinations[index];
    final currentName = current.attributeNameDraft;
    _updateCombinationAttributes(
      index,
      current,
      attributeName: currentName,
      attributeValue: rawValue.trim(),
    );
  }

  void updateCombinationPurchasePrice(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    final parsed = num.tryParse(rawValue.trim());
    if (variantCombinations[index].buyingPrice == parsed) {
      return;
    }
    variantCombinations[index] = variantCombinations[index].copyWith(
      buyingPrice: parsed,
    );
    variantCombinations.refresh();
    variantErrorMessage.value = null;
  }

  void updateCombinationSellingPrice(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    final parsed = num.tryParse(rawValue.trim());
    if (variantCombinations[index].sellingPrice == parsed) {
      return;
    }
    variantCombinations[index] = variantCombinations[index].copyWith(
      sellingPrice: parsed,
    );
    variantCombinations.refresh();
    variantErrorMessage.value = null;
  }

  void updateCombinationStatus(String key, String? value) {
    if (value == null) {
      return;
    }
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }

    final nextQuantity = value == 'inactive'
        ? 0
        : variantCombinations[index].quantity;
    variantCombinations[index] = variantCombinations[index].copyWith(
      status: value,
      quantity: nextQuantity,
    );
    variantCombinations.refresh();
    variantErrorMessage.value = null;
    _combinationStatusControllers[key] = value;

    final quantityController = _combinationQuantityControllers[key];
    if (quantityController != null &&
        quantityController.text != '$nextQuantity') {
      quantityController.value = quantityController.value.copyWith(
        text: '$nextQuantity',
        selection: TextSelection.collapsed(offset: '$nextQuantity'.length),
      );
    }
  }

  TextEditingController attributeNameController(String id) {
    final attribute = variantAttributes.firstWhereOrNull(
      (item) => item.id == id,
    );
    if (attribute == null) {
      return TextEditingController();
    }
    return _ensureAttributeControllers(attribute).$1;
  }

  TextEditingController attributeValuesController(String id) {
    final attribute = variantAttributes.firstWhereOrNull(
      (item) => item.id == id,
    );
    if (attribute == null) {
      return TextEditingController();
    }
    return _ensureAttributeControllers(attribute).$2;
  }

  FocusNode attributeNameFocusNode(String id) {
    return _attributeNameFocusNodes.putIfAbsent(id, FocusNode.new);
  }

  FocusNode attributeValuesFocusNode(String id) {
    return _attributeValuesFocusNodes.putIfAbsent(id, FocusNode.new);
  }

  TextEditingController combinationQuantityController(String key) {
    final existing = _combinationQuantityControllers[key];
    if (existing != null) {
      return existing;
    }
    final quantity =
        variantCombinations
            .firstWhereOrNull((combination) => combination.key == key)
            ?.quantity ??
        0;
    final controller = TextEditingController(text: '$quantity');
    controller.addListener(
      () => updateCombinationQuantity(key, controller.text),
    );
    _combinationQuantityControllers[key] = controller;
    return controller;
  }

  TextEditingController combinationAttributeNameController(String key) {
    final existing = _attributeNameControllers[key];
    if (existing != null) {
      return existing;
    }
    final value =
        variantCombinations
            .firstWhereOrNull((combination) => combination.key == key)
            ?.attributeNameDraft ??
        '';
    final controller = TextEditingController(text: value);
    controller.addListener(
      () => updateCombinationAttributeName(key, controller.text),
    );
    _attributeNameControllers[key] = controller;
    return controller;
  }

  TextEditingController combinationAttributeValueController(String key) {
    final existing = _attributeValuesControllers[key];
    if (existing != null) {
      return existing;
    }
    final value =
        variantCombinations
            .firstWhereOrNull((combination) => combination.key == key)
            ?.attributeValueDraft ??
        '';
    final controller = TextEditingController(text: value);
    controller.addListener(
      () => updateCombinationAttributeValue(key, controller.text),
    );
    _attributeValuesControllers[key] = controller;
    return controller;
  }

  TextEditingController combinationPurchasePriceController(String key) {
    final existing = _combinationPurchasePriceControllers[key];
    if (existing != null) {
      return existing;
    }
    final price = variantCombinations
        .firstWhereOrNull((combination) => combination.key == key)
        ?.buyingPrice;
    final controller = TextEditingController(
      text: price == null ? '' : '$price',
    );
    controller.addListener(
      () => updateCombinationPurchasePrice(key, controller.text),
    );
    _combinationPurchasePriceControllers[key] = controller;
    return controller;
  }

  TextEditingController combinationSellingPriceController(String key) {
    final existing = _combinationSellingPriceControllers[key];
    if (existing != null) {
      return existing;
    }
    final price = variantCombinations
        .firstWhereOrNull((combination) => combination.key == key)
        ?.sellingPrice;
    final controller = TextEditingController(
      text: price == null ? '' : '$price',
    );
    controller.addListener(
      () => updateCombinationSellingPrice(key, controller.text),
    );
    _combinationSellingPriceControllers[key] = controller;
    return controller;
  }

  String combinationStatusValue(String key) {
    final existing = _combinationStatusControllers[key];
    if (existing != null) {
      return existing;
    }
    final value =
        variantCombinations
            .firstWhereOrNull((combination) => combination.key == key)
            ?.status ??
        'active';
    _combinationStatusControllers[key] = value;
    return value;
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
    final variantPayload = _buildVariantPayload();
    if (isVariantsEnabled.value && variantPayload == null) {
      return;
    }

    final request = CreateOrUpdateBarcodeProductRequest(
      name: nameController.text.trim(),
      barcode: barcodeController.text.trim().isEmpty
          ? null
          : barcodeController.text.trim(),
      categoryId: categoryId,
      subcategoryId: selectedSubcategoryId.value,
      unitId: unitId,
      purchasePrice: isVariantsEnabled.value
          ? null
          : num.parse(purchasePriceController.text.trim()),
      sellingPrice: isVariantsEnabled.value
          ? null
          : num.parse(sellingPriceController.text.trim()),
      minimumStockAlert: int.parse(minimumStockController.text.trim()),
      status: selectedStatus.value,
      hasVariants: isVariantsEnabled.value ? true : null,
      variants: variantPayload,
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
          ? await _submitProductUpdate(request, readyPhotos)
          : isScanCreate
          ? await _inventoryManagerRepository.createProductFromBarcode(
              request,
              photos: readyPhotos,
            )
          : await _inventoryManagerRepository.createProduct(
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

  Future<ProductModel> _submitProductUpdate(
    CreateOrUpdateBarcodeProductRequest request,
    List<ProductPhotoUploadFile> readyPhotos,
  ) async {
    final productId = args.productId;
    if (productId != null) {
      return _inventoryManagerRepository.updateProduct(
        productId,
        request,
        photos: readyPhotos,
      );
    }

    return _inventoryManagerRepository.updateProductByBarcode(
      args.barcode ?? '',
      request,
      photos: readyPhotos,
    );
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

  void _seedVariantDrafts() {
    final attributes =
        args.variantAttributes ?? const <ProductVariantAttributeModel>[];
    if (attributes.isNotEmpty) {
      variantAttributes.assignAll(
        attributes.map(
          (attribute) => EditableVariantAttribute(
            id: 'attribute-${_nextAttributeId++}',
            serverId: attribute.id,
            name: attribute.name ?? '',
            values: attribute.values ?? const <String>[],
          ),
        ),
      );
      for (final attribute in variantAttributes) {
        _ensureAttributeControllers(attribute);
      }
    }

    final variants = args.variants ?? const <ProductVariantModel>[];
    if (variants.isNotEmpty) {
      variantCombinations.assignAll(
        variants.map(
          (variant) => VariantCombinationDraft(
            key: variant.combinationKey ?? _fallbackVariantKey(variant),
            label: variant.combinationLabel ?? '',
            attributes:
                variant.optionValues ??
                variant.attributes ??
                const <String, String>{},
            attributeNameDraft:
                (variant.optionValues ?? variant.attributes)
                    ?.keys
                    .firstOrNull ??
                '',
            attributeValueDraft:
                (variant.optionValues ?? variant.attributes)
                    ?.values
                    .firstOrNull ??
                '',
            sku: variant.sku,
            barcode: variant.barcode,
            quantity: variant.currentStock ?? 0,
            buyingPrice: variant.purchasePrice,
            sellingPrice: variant.sellingPrice,
            variantId: variant.id,
            status: (variant.status?.isNotEmpty ?? false)
                ? variant.status!
                : ((variant.isActive ?? true) ? 'active' : 'inactive'),
          ),
        ),
      );
      expandedVariantKey.value = variantCombinations.firstOrNull?.key;
      _syncCombinationControllers();
    }
  }

  List<ProductVariantRowPayload>? _buildVariantPayload() {
    variantErrorMessage.value = null;
    if (!isVariantsEnabled.value) {
      return null;
    }

    if (variantCombinations.isEmpty) {
      variantErrorMessage.value = 'Add at least one valid variant combination.';
      return null;
    }

    final seenCombinations = <String>{};
    final rows = <ProductVariantRowPayload>[];
    for (final combination in variantCombinations) {
      if (combination.attributes.isEmpty) {
        variantErrorMessage.value =
            'Every variant row must include at least one attribute.';
        return null;
      }
      final attributeName =
          combination.attributes.keys.firstOrNull?.trim() ?? '';
      final attributeValue =
          combination.attributes.values.firstOrNull?.trim() ?? '';
      if (attributeName.isEmpty || attributeValue.isEmpty) {
        variantErrorMessage.value =
            'Every variant row needs an attribute name and a value.';
        return null;
      }
      final derivedKey = _buildCombinationKey({attributeName: attributeValue});
      if (!seenCombinations.add(derivedKey)) {
        variantErrorMessage.value =
            'Duplicate variant combinations are not allowed.';
        return null;
      }
      final buyingPrice = combination.buyingPrice;
      if (buyingPrice == null || buyingPrice < 0) {
        variantErrorMessage.value =
            'Enter a valid purchase price for every variant combination.';
        return null;
      }
      final sellingPrice = combination.sellingPrice;
      if (sellingPrice == null || sellingPrice < 0) {
        variantErrorMessage.value =
            'Enter a valid selling price for every variant combination.';
        return null;
      }
      final quantity = combination.quantity < 0 ? 0 : combination.quantity;
      if (!combination.isActive && quantity != 0) {
        variantErrorMessage.value =
            'Inactive variants must have quantity set to 0.';
        return null;
      }

      rows.add(
        ProductVariantRowPayload(
          id: combination.variantId,
          attributes: {attributeName: attributeValue},
          quantity: combination.isActive ? quantity : 0,
          buyingPrice: buyingPrice,
          sellingPrice: sellingPrice,
          status: combination.status,
        ),
      );
    }

    return rows;
  }

  void _regenerateVariantCombinations({bool syncInputs = true}) {
    if (!isVariantsEnabled.value) {
      variantCombinations.clear();
      return;
    }
    if (syncInputs) {
      _syncAttributeDraftsFromControllers();
    }

    final sourceAttributes = variantAttributes
        .map(
          (attribute) => EditableVariantAttribute(
            id: attribute.id,
            serverId: attribute.serverId,
            name: attribute.name.trim(),
            values: attribute.values
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(),
          ),
        )
        .where(
          (attribute) =>
              attribute.name.isNotEmpty && attribute.values.isNotEmpty,
        )
        .toList();

    if (sourceAttributes.isEmpty) {
      variantCombinations.clear();
      return;
    }

    final existingByKey = <String, VariantCombinationDraft>{
      for (final combination in variantCombinations)
        combination.key: combination,
    };
    final generated = _cartesianCombinations(sourceAttributes).map((
      optionValues,
    ) {
      final key = _buildCombinationKey(optionValues);
      final existing = existingByKey[key];
      return VariantCombinationDraft(
        key: key,
        label: optionValues.values.join(' / '),
        attributes: optionValues,
        quantity: existing?.quantity ?? 0,
        buyingPrice: existing?.buyingPrice,
        sellingPrice: existing?.sellingPrice,
        variantId: existing?.variantId,
        status: existing?.status ?? 'active',
      );
    }).toList();
    variantCombinations.assignAll(generated);
    _syncCombinationControllers();
  }

  void _syncAttributeDraftsFromControllers() {
    for (var index = 0; index < variantAttributes.length; index++) {
      final attribute = variantAttributes[index];
      final rawName = _attributeNameControllers[attribute.id]?.text;
      final rawValues = _attributeValuesControllers[attribute.id]?.text;
      final nextName = rawName == null || rawName.trim().isEmpty
          ? attribute.name.trim()
          : rawName.trim();
      final nextValues = rawValues == null || rawValues.trim().isEmpty
          ? attribute.values
          : _parseVariantValues(rawValues);
      if (attribute.name == nextName &&
          _listEquals(attribute.values, nextValues)) {
        continue;
      }
      variantAttributes[index] = attribute.copyWith(
        name: nextName,
        values: nextValues,
      );
    }
    variantAttributes.refresh();
  }

  List<String> _parseVariantValues(String rawValue) {
    return rawValue
        .split(RegExp(r'[\n,;]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  List<Map<String, String>> _cartesianCombinations(
    List<EditableVariantAttribute> attributes,
  ) {
    var combinations = <Map<String, String>>[<String, String>{}];

    for (final attribute in attributes) {
      final next = <Map<String, String>>[];
      for (final combination in combinations) {
        for (final value in attribute.values) {
          next.add(<String, String>{...combination, attribute.name: value});
        }
      }
      combinations = next;
    }

    return combinations;
  }

  String _buildCombinationKey(Map<String, String> optionValues) {
    return optionValues.entries
        .map((entry) => '${_slugify(entry.key)}-${_slugify(entry.value)}')
        .join('__');
  }

  String _resolveInitialBaseBarcode() {
    final existing = args.barcode?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return '';
  }

  String _fallbackVariantKey(ProductVariantModel variant) {
    final optionValues = variant.optionValues ?? variant.attributes;
    if (optionValues == null || optionValues.isEmpty) {
      return variant.combinationKey ?? 'variant-${variant.id ?? 0}';
    }
    return _buildCombinationKey(optionValues);
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _createPhotoId() => 'photo-${_nextPhotoId++}';
  String _createManualVariantKey() => 'variant-row-${_nextVariantDraftId++}';

  void _updateCombinationAttributes(
    int index,
    VariantCombinationDraft current, {
    required String attributeName,
    required String attributeValue,
  }) {
    final trimmedName = attributeName.trim();
    final trimmedValue = attributeValue.trim();
    final nextAttributes = trimmedName.isEmpty || trimmedValue.isEmpty
        ? const <String, String>{}
        : <String, String>{trimmedName: trimmedValue};
    variantCombinations[index] = current.copyWith(
      label: trimmedValue.isEmpty ? 'New Variant' : trimmedValue,
      attributes: nextAttributes,
      attributeNameDraft: trimmedName,
      attributeValueDraft: trimmedValue,
    );
    variantCombinations.refresh();
    variantErrorMessage.value = null;
    update(['variant_rows']);
  }

  (TextEditingController, TextEditingController) _ensureAttributeControllers(
    EditableVariantAttribute attribute,
  ) {
    final nameController = _attributeNameControllers.putIfAbsent(
      attribute.id,
      () => TextEditingController(text: attribute.name),
    );
    final valuesController = _attributeValuesControllers.putIfAbsent(
      attribute.id,
      () => TextEditingController(text: attributeValuesLabel(attribute)),
    );
    final nameFocusNode = _attributeNameFocusNodes.putIfAbsent(
      attribute.id,
      FocusNode.new,
    );
    final valuesFocusNode = _attributeValuesFocusNodes.putIfAbsent(
      attribute.id,
      FocusNode.new,
    );

    if (!nameFocusNode.hasFocus && nameController.text != attribute.name) {
      nameController.value = nameController.value.copyWith(
        text: attribute.name,
        selection: TextSelection.collapsed(offset: attribute.name.length),
      );
    }
    final valuesText = attributeValuesLabel(attribute);
    if (!valuesFocusNode.hasFocus && valuesController.text != valuesText) {
      valuesController.value = valuesController.value.copyWith(
        text: valuesText,
        selection: TextSelection.collapsed(offset: valuesText.length),
      );
    }

    return (nameController, valuesController);
  }

  void _syncCombinationControllers() {
    final validKeys = variantCombinations.map((item) => item.key).toSet();
    final staleAttributeNameKeys = _attributeNameControllers.keys
        .where(
          (key) => !key.startsWith('attribute-') && !validKeys.contains(key),
        )
        .toList();
    final staleAttributeValueKeys = _attributeValuesControllers.keys
        .where(
          (key) => !key.startsWith('attribute-') && !validKeys.contains(key),
        )
        .toList();
    final staleKeys = _combinationQuantityControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    final stalePurchasePriceKeys = _combinationPurchasePriceControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    final staleSellingPriceKeys = _combinationSellingPriceControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    final staleStatusKeys = _combinationStatusControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    for (final key in staleAttributeNameKeys) {
      _attributeNameControllers.remove(key)?.dispose();
    }
    for (final key in staleAttributeValueKeys) {
      _attributeValuesControllers.remove(key)?.dispose();
    }
    for (final key in staleKeys) {
      _combinationQuantityControllers.remove(key)?.dispose();
    }
    for (final key in stalePurchasePriceKeys) {
      _combinationPurchasePriceControllers.remove(key)?.dispose();
    }
    for (final key in staleSellingPriceKeys) {
      _combinationSellingPriceControllers.remove(key)?.dispose();
    }
    for (final key in staleStatusKeys) {
      _combinationStatusControllers.remove(key);
    }

    for (final combination in variantCombinations) {
      final attributeNameController = _attributeNameControllers.putIfAbsent(
        combination.key,
        () {
          final next = TextEditingController(
            text: combination.attributeNameDraft,
          );
          next.addListener(
            () => updateCombinationAttributeName(combination.key, next.text),
          );
          return next;
        },
      );
      final nextAttributeNameText = combination.attributeNameDraft;
      if (attributeNameController.text != nextAttributeNameText) {
        attributeNameController.value = attributeNameController.value.copyWith(
          text: nextAttributeNameText,
          selection: TextSelection.collapsed(
            offset: nextAttributeNameText.length,
          ),
        );
      }
      final attributeValueController = _attributeValuesControllers.putIfAbsent(
        combination.key,
        () {
          final next = TextEditingController(
            text: combination.attributeValueDraft,
          );
          next.addListener(
            () => updateCombinationAttributeValue(combination.key, next.text),
          );
          return next;
        },
      );
      final nextAttributeValueText = combination.attributeValueDraft;
      if (attributeValueController.text != nextAttributeValueText) {
        attributeValueController.value = attributeValueController.value
            .copyWith(
              text: nextAttributeValueText,
              selection: TextSelection.collapsed(
                offset: nextAttributeValueText.length,
              ),
            );
      }
      final controller = _combinationQuantityControllers.putIfAbsent(
        combination.key,
        () {
          final next = TextEditingController(text: '${combination.quantity}');
          next.addListener(
            () => updateCombinationQuantity(combination.key, next.text),
          );
          return next;
        },
      );
      final nextText = '${combination.quantity}';
      if (controller.text != nextText) {
        controller.value = controller.value.copyWith(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      }

      final purchasePriceController = _combinationPurchasePriceControllers
          .putIfAbsent(combination.key, () {
            final next = TextEditingController(
              text: combination.buyingPrice?.toString() ?? '',
            );
            next.addListener(
              () => updateCombinationPurchasePrice(combination.key, next.text),
            );
            return next;
          });
      final nextPurchasePriceText = combination.buyingPrice?.toString() ?? '';
      if (purchasePriceController.text != nextPurchasePriceText) {
        purchasePriceController.value = purchasePriceController.value.copyWith(
          text: nextPurchasePriceText,
          selection: TextSelection.collapsed(
            offset: nextPurchasePriceText.length,
          ),
        );
      }

      final sellingPriceController = _combinationSellingPriceControllers
          .putIfAbsent(combination.key, () {
            final next = TextEditingController(
              text: combination.sellingPrice?.toString() ?? '',
            );
            next.addListener(
              () => updateCombinationSellingPrice(combination.key, next.text),
            );
            return next;
          });
      final nextSellingPriceText = combination.sellingPrice?.toString() ?? '';
      if (sellingPriceController.text != nextSellingPriceText) {
        sellingPriceController.value = sellingPriceController.value.copyWith(
          text: nextSellingPriceText,
          selection: TextSelection.collapsed(
            offset: nextSellingPriceText.length,
          ),
        );
      }

      _combinationStatusControllers[combination.key] = combination.status;
    }
  }

  void _disposeVariantControllers() {
    for (final controller in _attributeNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _attributeValuesControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _attributeNameFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _attributeValuesFocusNodes.values) {
      focusNode.dispose();
    }
    for (final controller in _combinationQuantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _combinationPurchasePriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _combinationSellingPriceControllers.values) {
      controller.dispose();
    }
    _attributeNameControllers.clear();
    _attributeValuesControllers.clear();
    _attributeNameFocusNodes.clear();
    _attributeValuesFocusNodes.clear();
    _combinationQuantityControllers.clear();
    _combinationPurchasePriceControllers.clear();
    _combinationSellingPriceControllers.clear();
    _combinationStatusControllers.clear();
  }

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
