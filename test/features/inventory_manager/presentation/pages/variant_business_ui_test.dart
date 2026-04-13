// ignore_for_file: must_call_super

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/repositories/inventory_manager_repository.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/controllers/product_form_controller.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/controllers/purchase_details_controller.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/models/product_form_args.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/models/editable_variant_attribute.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/models/variant_combination_draft.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/pages/purchase_details_page.dart';
import 'package:inventory_management_sales/features/products/data/models/product_model.dart';
import 'package:inventory_management_sales/features/products/data/models/product_variant_attribute_model.dart';
import 'package:inventory_management_sales/features/products/data/models/product_variant_model.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';

class _TestProductFormController extends ProductFormController {
  _TestProductFormController({
    required super.inventoryManagerRepository,
    this.formArgs = const ProductFormArgs.create(),
  });

  final ProductFormArgs formArgs;

  @override
  void onInit() {
    args = formArgs;
    nameController = TextEditingController(text: args.name ?? '');
    skuController = TextEditingController(text: args.sku ?? '');
    barcodeController = TextEditingController(text: args.barcode ?? 'BC-1');
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
    _seedVariantDraftsForTest();

    if (args.mode == ProductFormMode.create) {
      isVariantsEnabled.value = true;
      addVariantAttribute();
      super.variantAttributes[0] = super.variantAttributes[0].copyWith(
        name: 'Color',
        values: const ['Red', 'Blue'],
      );
      super.variantAttributes.refresh();
      super.onVariantsToggled(true);
    }
  }

  void _seedVariantDraftsForTest() {
    final attributes = args.variantAttributes ?? const [];
    if (attributes.isNotEmpty) {
      super.variantAttributes.assignAll(
        attributes.map(
          (attribute) => EditableVariantAttribute(
            id: 'attribute-${attribute.id ?? attribute.name}',
            serverId: attribute.id,
            name: attribute.name ?? '',
            values: attribute.values ?? const <String>[],
          ),
        ),
      );
    }

    final variants = args.variants ?? const [];
    if (variants.isNotEmpty) {
      super.variantCombinations.assignAll(
        variants.map(
          (variant) => VariantCombinationDraft(
            key: variant.combinationKey ?? 'variant-${variant.id ?? 0}',
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
    }
  }
}

class _TestPurchaseDetailsController extends PurchaseDetailsController {
  _TestPurchaseDetailsController({
    required super.inventoryManagerRepository,
    required super.productRepository,
  });

  @override
  void onInit() {
    product.value = const ProductModel(
      id: 1,
      name: 'Classic T-Shirt',
      hasVariants: true,
      purchasePrice: 220,
      variants: [
        ProductVariantModel(
          id: 11,
          combinationKey: 'color-red__size-m',
          combinationLabel: 'Red / M',
          optionValues: {'Color': 'Red', 'Size': 'M'},
          purchasePrice: 180,
          sellingPrice: 240,
          currentStock: 5,
          isActive: true,
        ),
      ],
    );
    unitCostController.text = '220.00';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  InventoryManagerRepository inventoryRepo() {
    return InventoryManagerRepository(
      productRepository: ProductRepository(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      ),
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  ProductRepository productRepo() {
    return ProductRepository(
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      ),
      tokenStorage: TokenStorage(),
    );
  }

  test('product form controller prepares variant business state', () {
    final controller = _TestProductFormController(
      inventoryManagerRepository: inventoryRepo(),
    );

    controller.onInit();

    expect(controller.showVariantSection, isTrue);
    expect(controller.variantAttributeCount, 1);
    expect(controller.variantCombinationCount, 2);
    expect(controller.hasIncompleteVariantRows, isFalse);
  });

  test('product form controller preserves variant edit prefills', () {
    final controller = _TestProductFormController(
      inventoryManagerRepository: inventoryRepo(),
      formArgs: const ProductFormArgs.edit(
        productId: 2,
        name: 'Sepnil',
        barcode: '8941100506066',
        categoryId: 2,
        subcategoryId: 5,
        unitId: 1,
        hasVariants: true,
        variantAttributes: [
          ProductVariantAttributeModel(
            id: 5,
            name: 'Size',
            values: ['50 ml', '100 ml', '150ml'],
          ),
        ],
        variants: [
          ProductVariantModel(
            id: 4,
            combinationKey: 'size-50-ml',
            combinationLabel: '50 ml',
            optionValues: {'Size': '50 ml'},
            purchasePrice: 30,
            sellingPrice: 40,
            currentStock: 0,
            isActive: true,
          ),
          ProductVariantModel(
            id: 5,
            combinationKey: 'size-100-ml',
            combinationLabel: '100 ml',
            optionValues: {'Size': '100 ml'},
            purchasePrice: 38,
            sellingPrice: 50,
            currentStock: 0,
            isActive: true,
          ),
        ],
      ),
    );

    controller.onInit();

    expect(controller.isEdit, isTrue);
    expect(controller.args.productId, 2);
    expect(controller.showVariantSection, isTrue);
    expect(controller.selectedCategoryId.value, 2);
    expect(controller.selectedSubcategoryId.value, 5);
    expect(controller.variantAttributeCount, 1);
    expect(controller.variantCombinationCount, 2);
    expect(controller.variantAttributes.first.name, 'Size');
    expect(controller.variantAttributes.first.values, [
      '50 ml',
      '100 ml',
      '150ml',
    ]);
    expect(controller.variantCombinations.map((item) => item.key).toList(), [
      'size-50-ml',
      'size-100-ml',
    ]);
    expect(controller.variantCombinations.first.purchasePrice, 30);
    expect(controller.variantCombinations.first.sellingPrice, 40);
  });

  testWidgets(
    'purchase page shows explicit variant choices for variant products',
    (tester) async {
      Get.put<PurchaseDetailsController>(
        _TestPurchaseDetailsController(
          inventoryManagerRepository: inventoryRepo(),
          productRepository: productRepo(),
        ),
      );

      await tester.pumpWidget(
        const GetMaterialApp(home: PurchaseDetailsPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Variant'), findsOneWidget);
      expect(find.text('Red / M'), findsOneWidget);
      expect(find.textContaining('Stock 5'), findsOneWidget);
      expect(find.textContaining('Buy ৳180'), findsOneWidget);
    },
  );
}
