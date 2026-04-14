import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../models/purchase_draft_item.dart';
import '../models/purchase_line_editor_args.dart';

class PurchaseDetailsController extends GetxController {
  PurchaseDetailsController({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final quantityController = TextEditingController(text: '1');
  final unitCostController = TextEditingController();

  final product = Rxn<ProductModel>();
  final quantityError = RxnString();
  final unitCostError = RxnString();
  final submitError = RxnString();
  final isVariantLoading = false.obs;
  final selectedVariantId = RxnInt();
  final initialItem = Rxn<PurchaseDraftItem>();

  int? get quantity => int.tryParse(quantityController.text.trim());
  double? get unitCost => double.tryParse(unitCostController.text.trim());
  List<ProductVariantModel> get activeVariants =>
      (product.value?.variants ?? const [])
          .where((variant) => variant.isActive ?? true)
          .toList(growable: false);
  bool get requiresVariantSelection => product.value?.hasVariants == true;
  bool get hasSelectableVariants => activeVariants.isNotEmpty;
  ProductVariantModel? get selectedVariant => activeVariants.firstWhereOrNull(
    (variant) => variant.id == selectedVariantId.value,
  );
  String? get selectedVariantLabel {
    return selectedVariant?.resolvedLabel;
  }

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
    final resolvedArgs = switch (argument) {
      final PurchaseLineEditorArgs args => args,
      final ProductModel product => PurchaseLineEditorArgs(product: product),
      _ => null,
    };
    if (resolvedArgs == null) {
      throw ArgumentError(
        'PurchaseDetailsPage requires purchase line arguments.',
      );
    }

    product.value = resolvedArgs.product;
    initialItem.value = resolvedArgs.initialItem;
    final initialVariantId =
        resolvedArgs.initialItem?.productVariantId ??
        resolvedArgs.product.matchedVariant?.id;
    selectedVariantId.value = initialVariantId;
    quantityController.text = '${resolvedArgs.initialItem?.quantity ?? 1}';
    unitCostController.text = _resolveInitialUnitCost(
      resolvedArgs,
    ).toStringAsFixed(2);
    quantityController.addListener(_handleInputChange);
    unitCostController.addListener(_handleInputChange);
    _ensureVariantDetailsLoaded();
  }

  @override
  void onClose() {
    quantityController
      ..removeListener(_handleInputChange)
      ..dispose();
    unitCostController
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

  void submitLine() {
    final currentProduct = product.value;
    if (currentProduct == null) {
      return;
    }

    final validation = _validate(currentProduct);
    if (!validation.isValid) {
      quantityError.value = validation.quantityError;
      unitCostError.value = validation.unitCostError;
      submitError.value = validation.variantError;
      return;
    }

    final selectedVariantModel = selectedVariant;
    final optionValues =
        selectedVariantModel?.optionValues ??
        currentProduct.matchedVariant?.optionValues;
    final variantLabel =
        selectedVariantModel?.resolvedLabel ??
        currentProduct.matchedVariant?.resolvedLabel;
    final currentStock =
        selectedVariantModel?.currentStock ?? currentProduct.currentStock ?? 0;

    Get.back(
      result: PurchaseDraftItem(
        lineKey: _lineKeyFor(currentProduct.id!, selectedVariantId.value),
        productId: currentProduct.id!,
        productVariantId: selectedVariantId.value,
        variantLabel: variantLabel,
        optionValues: optionValues,
        name: currentProduct.name ?? 'Unnamed product',
        sku: selectedVariantModel?.sku ?? currentProduct.sku ?? '-',
        barcode:
            selectedVariantModel?.barcode ??
            currentProduct.barcode ??
            'No barcode',
        quantity: validation.quantity!,
        unitCost: validation.unitCost!,
        currentStock: currentStock,
        categoryName: currentProduct.category?.name ?? 'Uncategorized product',
        product: currentProduct,
      ),
    );
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
      unitCostError: parsedUnitCost == null || parsedUnitCost < 0
          ? 'Unit cost must be 0 or more.'
          : null,
      variantError: product.hasVariants == true && !hasSelectableVariants
          ? 'No active variants are available for this product.'
          : product.hasVariants == true && selectedVariantId.value == null
          ? 'Select a variant before submitting this purchase.'
          : null,
    );
  }

  void _handleInputChange() {
    quantityError.value = null;
    unitCostError.value = null;
    submitError.value = null;
  }

  void onVariantChanged(int? variantId) {
    selectedVariantId.value = variantId;
    final purchasePrice = selectedVariant?.purchasePrice;
    if (purchasePrice != null) {
      unitCostController.text = purchasePrice.toStringAsFixed(2);
    }
    submitError.value = null;
  }

  Future<void> _ensureVariantDetailsLoaded() async {
    final currentProduct = product.value;
    if (currentProduct?.id == null || currentProduct?.hasVariants != true) {
      return;
    }
    if ((currentProduct?.variants ?? const []).isNotEmpty) {
      return;
    }

    isVariantLoading.value = true;
    try {
      final response = await _productRepository.fetchProductDetails(
        currentProduct!.id!,
        forceRefresh: true,
      );
      if (response.data != null) {
        product.value = response.data;
      }
    } catch (_) {
      submitError.value =
          'Unable to load product variants right now. Try again.';
    } finally {
      isVariantLoading.value = false;
    }
  }

  double _resolveInitialUnitCost(PurchaseLineEditorArgs args) {
    final unitCostFromDraft = args.initialItem?.unitCost;
    if (unitCostFromDraft != null) {
      return unitCostFromDraft;
    }

    final matchedVariantPrice = args.product.matchedVariant?.purchasePrice;
    if (matchedVariantPrice != null) {
      return matchedVariantPrice.toDouble();
    }

    return (args.product.purchasePrice ?? 0).toDouble();
  }

  String _lineKeyFor(int productId, int? productVariantId) {
    return '$productId:${productVariantId ?? 'base'}';
  }
}

class PurchaseSubmissionValidation {
  const PurchaseSubmissionValidation({
    required this.quantity,
    required this.unitCost,
    required this.quantityError,
    required this.unitCostError,
    required this.variantError,
  });

  final int? quantity;
  final double? unitCost;
  final String? quantityError;
  final String? unitCostError;
  final String? variantError;

  bool get isValid =>
      quantityError == null && unitCostError == null && variantError == null;
}
