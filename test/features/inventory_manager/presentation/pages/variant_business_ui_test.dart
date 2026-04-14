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
    barcodeController = TextEditingController(
      text:
          args.barcode ??
          (args.source == ProductFormSource.manual ? 'BC-AUTO-1' : 'BC-1'),
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
    }
  }
}

class _TestPurchaseDetailsController extends PurchaseDetailsController {
  _TestPurchaseDetailsController({required super.productRepository});

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
    expect(controller.variantCombinationCount, 1);
    expect(controller.variantCombinations.first.attributes, isEmpty);
    expect(controller.variantCombinations.first.label, 'New Variant');
  });

  test('product form controller can add another manual variant row', () {
    final controller = _TestProductFormController(
      inventoryManagerRepository: inventoryRepo(),
    );

    controller.onInit();
    controller.addVariantRow();

    expect(controller.variantCombinationCount, 2);
    expect(
      controller.variantCombinations.map((item) => item.key).toSet().length,
      2,
    );
  });

  test(
    'product form controller generates variant rows from current text inputs',
    () {
      final controller = _TestProductFormController(
        inventoryManagerRepository: inventoryRepo(),
        formArgs: const ProductFormArgs.create(hasVariants: true),
      );

      controller.onInit();
      controller
              .attributeNameController(controller.variantAttributes.first.id)
              .text =
          'Size';
      controller
              .attributeValuesController(controller.variantAttributes.first.id)
              .text =
          '1,2,3';

      controller.generateVariantRows();

      expect(controller.variantCombinationCount, 3);
      expect(
        controller.variantCombinations.map((item) => item.label).toList(),
        ['1', '2', '3'],
      );
    },
  );

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
            sku: 'SEP-50',
            barcode: '8941100506066-SIZE-50-ML',
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
            sku: 'SEP-100',
            barcode: '8941100506066-SIZE-100-ML',
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
    expect(controller.variantCombinations.first.buyingPrice, 30);
    expect(controller.variantCombinations.first.sellingPrice, 40);
    expect(controller.variantCombinations.first.sku, 'SEP-50');
    expect(
      controller.variantCombinations.first.barcode,
      '8941100506066-SIZE-50-ML',
    );
    expect(controller.variantCombinations.first.status, 'active');
  });

  test('product form controller keeps variant row state on regeneration', () {
    final controller = _TestProductFormController(
      inventoryManagerRepository: inventoryRepo(),
      formArgs: const ProductFormArgs.edit(
        productId: 2,
        name: 'Phone',
        barcode: 'BC-BASE-1',
        categoryId: 2,
        unitId: 1,
        hasVariants: true,
        variantAttributes: [
          ProductVariantAttributeModel(
            id: 5,
            name: 'Storage',
            values: ['128', '256'],
          ),
        ],
        variants: [
          ProductVariantModel(
            id: 4,
            combinationKey: 'storage-128',
            combinationLabel: '128',
            sku: 'PH-128',
            barcode: 'BC-BASE-1-STORAGE-128',
            optionValues: {'Storage': '128'},
            purchasePrice: 30,
            sellingPrice: 40,
            currentStock: 5,
            isActive: true,
          ),
        ],
      ),
    );

    controller.onInit();
    controller.updateCombinationPurchasePrice('storage-128', '35');
    controller.updateCombinationSellingPrice('storage-128', '45');
    controller.updateCombinationQuantity('storage-128', '7');
    controller
            .attributeValuesController(controller.variantAttributes.first.id)
            .text =
        '128,256,512';

    controller.generateVariantRows();

    final preserved = controller.variantCombinations.firstWhere(
      (item) => item.key == 'storage-128',
    );
    final added = controller.variantCombinations.firstWhere(
      (item) => item.key == 'storage-512',
    );

    expect(preserved.sku, 'PH-128');
    expect(preserved.barcode, 'BC-BASE-1-STORAGE-128');
    expect(preserved.buyingPrice, 35);
    expect(preserved.sellingPrice, 45);
    expect(preserved.quantity, 7);
    expect(added.barcode, 'BC-BASE-1-STORAGE-512');
  });

  test(
    'product form controller forces inactive variant quantities to zero',
    () {
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
              values: ['50 ml'],
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
              currentStock: 12,
              isActive: true,
            ),
          ],
        ),
      );

      controller.onInit();
      controller.updateCombinationStatus('size-50-ml', 'inactive');

      expect(controller.variantCombinations.first.status, 'inactive');
      expect(controller.variantCombinations.first.quantity, 0);
      expect(controller.combinationQuantityController('size-50-ml').text, '0');
    },
  );

  testWidgets(
    'purchase page shows explicit variant choices for variant products',
    (tester) async {
      Get.put<PurchaseDetailsController>(
        _TestPurchaseDetailsController(productRepository: productRepo()),
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
