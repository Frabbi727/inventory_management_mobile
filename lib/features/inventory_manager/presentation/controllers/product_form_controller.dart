import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_subcategory_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import '../../../products/data/models/product_variant_attribute_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../data/models/create_or_update_barcode_product_request.dart';
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
  late final TextEditingController skuController;
  late final TextEditingController barcodeController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController sellingPriceController;
  late final TextEditingController minimumStockController;
  final _attributeNameControllers = <String, TextEditingController>{};
  final _attributeValuesControllers = <String, TextEditingController>{};
  final _combinationQuantityControllers = <String, TextEditingController>{};
  final _combinationPurchasePriceControllers =
      <String, TextEditingController>{};
  final _combinationSellingPriceControllers = <String, TextEditingController>{};

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

  int _nextPhotoId = 0;
  int _nextAttributeId = 0;

  bool get isEdit => args.mode == ProductFormMode.edit;
  bool get hasPendingCompression =>
      selectedPhotos.any((photo) => photo.isCompressing);
  bool get showVariantSection => isVariantsEnabled.value;
  bool get showBasePriceFields => !isVariantsEnabled.value;
  bool get isSubcategoryEnabled =>
      !isSubcategoryLoading.value && selectedCategoryId.value != null;
  int get variantAttributeCount => variantAttributes.length;
  int get variantCombinationCount => variantCombinations.length;
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
    skuController.dispose();
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
      if (variantAttributes.isEmpty) {
        addVariantAttribute();
      }
      _regenerateVariantCombinations();
      return;
    }

    _disposeVariantControllers();
    variantAttributes.clear();
    variantCombinations.clear();
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

  void updateCombinationPurchasePrice(String key, String rawValue) {
    final index = variantCombinations.indexWhere(
      (combination) => combination.key == key,
    );
    if (index == -1) {
      return;
    }
    final parsed = num.tryParse(rawValue.trim());
    if (variantCombinations[index].purchasePrice == parsed) {
      return;
    }
    variantCombinations[index] = variantCombinations[index].copyWith(
      purchasePrice: parsed,
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

  TextEditingController combinationPurchasePriceController(String key) {
    final existing = _combinationPurchasePriceControllers[key];
    if (existing != null) {
      return existing;
    }
    final price = variantCombinations
        .firstWhereOrNull((combination) => combination.key == key)
        ?.purchasePrice;
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
      sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
      barcode: barcodeController.text.trim(),
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
      variantAttributes: variantPayload?.$1,
      variantQuantities: variantPayload?.$2,
      variantPurchasePrices: variantPayload?.$3,
      variantSellingPrices: variantPayload?.$4,
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
            optionValues: variant.optionValues ?? const <String, String>{},
            quantity: variant.currentStock ?? 0,
            purchasePrice: variant.purchasePrice,
            sellingPrice: variant.sellingPrice,
            variantId: variant.id,
            isActive: variant.isActive ?? true,
          ),
        ),
      );
      _syncCombinationControllers();
    }
  }

  (
    List<ProductVariantAttributePayload>,
    Map<String, int>,
    Map<String, num>,
    Map<String, num>,
  )?
  _buildVariantPayload() {
    variantErrorMessage.value = null;
    if (!isVariantsEnabled.value) {
      return null;
    }

    final sanitizedAttributes = variantAttributes
        .map(
          (attribute) => ProductVariantAttributePayload(
            name: attribute.name.trim(),
            values: attribute.values
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList(),
          ),
        )
        .where(
          (attribute) =>
              attribute.name.isNotEmpty && attribute.values.isNotEmpty,
        )
        .toList();

    if (sanitizedAttributes.isEmpty) {
      variantErrorMessage.value =
          'Add at least one variant attribute with values.';
      return null;
    }

    final uniqueNames = sanitizedAttributes
        .map((attribute) => attribute.name.trim().toLowerCase())
        .toSet();
    if (uniqueNames.length != sanitizedAttributes.length) {
      variantErrorMessage.value = 'Variant attribute names must be unique.';
      return null;
    }

    if (variantCombinations.isEmpty) {
      variantErrorMessage.value = 'Add at least one valid variant combination.';
      return null;
    }

    final quantities = <String, int>{};
    final purchasePrices = <String, num>{};
    final sellingPrices = <String, num>{};
    for (final combination in variantCombinations) {
      quantities[combination.key] = combination.quantity;
      final purchasePrice = combination.purchasePrice;
      if (purchasePrice == null || purchasePrice < 0) {
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
      purchasePrices[combination.key] = purchasePrice;
      sellingPrices[combination.key] = sellingPrice;
    }

    return (sanitizedAttributes, quantities, purchasePrices, sellingPrices);
  }

  void _regenerateVariantCombinations() {
    if (!isVariantsEnabled.value) {
      variantCombinations.clear();
      return;
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
        optionValues: optionValues,
        quantity: existing?.quantity ?? 0,
        purchasePrice: existing?.purchasePrice,
        sellingPrice: existing?.sellingPrice,
        variantId: existing?.variantId,
        isActive: existing?.isActive ?? true,
      );
    }).toList();
    variantCombinations.assignAll(generated);
    _syncCombinationControllers();
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

  String _fallbackVariantKey(ProductVariantModel variant) {
    final optionValues = variant.optionValues;
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

    if (nameController.text != attribute.name) {
      nameController.value = nameController.value.copyWith(
        text: attribute.name,
        selection: TextSelection.collapsed(offset: attribute.name.length),
      );
    }
    final valuesText = attributeValuesLabel(attribute);
    if (valuesController.text != valuesText) {
      valuesController.value = valuesController.value.copyWith(
        text: valuesText,
        selection: TextSelection.collapsed(offset: valuesText.length),
      );
    }

    return (nameController, valuesController);
  }

  void _syncCombinationControllers() {
    final validKeys = variantCombinations.map((item) => item.key).toSet();
    final staleKeys = _combinationQuantityControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    final stalePurchasePriceKeys = _combinationPurchasePriceControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    final staleSellingPriceKeys = _combinationSellingPriceControllers.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    for (final key in staleKeys) {
      _combinationQuantityControllers.remove(key)?.dispose();
    }
    for (final key in stalePurchasePriceKeys) {
      _combinationPurchasePriceControllers.remove(key)?.dispose();
    }
    for (final key in staleSellingPriceKeys) {
      _combinationSellingPriceControllers.remove(key)?.dispose();
    }

    for (final combination in variantCombinations) {
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
              text: combination.purchasePrice?.toString() ?? '',
            );
            next.addListener(
              () => updateCombinationPurchasePrice(combination.key, next.text),
            );
            return next;
          });
      final nextPurchasePriceText = combination.purchasePrice?.toString() ?? '';
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
    }
  }

  void _disposeVariantControllers() {
    for (final controller in _attributeNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _attributeValuesControllers.values) {
      controller.dispose();
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
    _combinationQuantityControllers.clear();
    _combinationPurchasePriceControllers.clear();
    _combinationSellingPriceControllers.clear();
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
