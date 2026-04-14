import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/routes/app_routes.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/models/barcode_resolve_response.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/repositories/inventory_manager_repository.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/controllers/barcode_scan_controller.dart';
import 'package:inventory_management_sales/features/inventory_manager/presentation/models/barcode_scan_models.dart';
import 'package:inventory_management_sales/features/products/data/models/product_model.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInventoryManagerRepository extends InventoryManagerRepository {
  _FakeInventoryManagerRepository({
    required this.resolveHandler,
    required this.barcodeLookupHandler,
  }) : super(
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

  final Future<BarcodeResolveResponse> Function(String barcode) resolveHandler;
  final Future<ProductModel> Function(String barcode) barcodeLookupHandler;

  @override
  Future<BarcodeResolveResponse> resolveProductBarcode(String barcode) {
    return resolveHandler(barcode);
  }

  @override
  Future<ProductModel> getProductByBarcode(String barcode) {
    return barcodeLookupHandler(barcode);
  }
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository({required this.barcodeLookupHandler})
    : super(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final Future<ProductModel> Function(String barcode) barcodeLookupHandler;

  @override
  Future<ProductModel> fetchProductByBarcode(String barcode) {
    return barcodeLookupHandler(barcode);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'barcode-token',
    });
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  Widget testApp() {
    return GetMaterialApp(
      getPages: [
        GetPage(
          name: AppRoutes.inventoryProductForm,
          page: () => const Scaffold(body: Text('create-page')),
        ),
        GetPage(
          name: AppRoutes.productDetails,
          page: () =>
              Scaffold(body: Text('details-${Get.arguments.runtimeType}')),
        ),
      ],
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }

  testWidgets('opens create form when barcode does not exist', (tester) async {
    final repository = _FakeInventoryManagerRepository(
      resolveHandler: (barcode) async => BarcodeResolveResponse(
        message: 'not found',
        exists: false,
        action: 'create',
        barcode: barcode,
        matchType: null,
        data: null,
        variant: null,
      ),
      barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
    );

    final controller = BarcodeScanController(
      inventoryManagerRepository: repository,
      productRepository: _FakeProductRepository(
        barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
      ),
    );
    Get.put(controller);

    await tester.pumpWidget(testApp());
    await controller.resolveBarcode('BC-001');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.inventoryProductForm);
  });

  testWidgets(
    'opens product details when resolve says create but barcode details lookup succeeds',
    (tester) async {
      final repository = _FakeInventoryManagerRepository(
        resolveHandler: (barcode) async => BarcodeResolveResponse(
          message: 'not found',
          exists: false,
          action: 'create',
          barcode: barcode,
          matchType: null,
          data: null,
          variant: null,
        ),
        barcodeLookupHandler: (barcode) async =>
            const ProductModel(id: 9, name: 'Recovered Existing Product'),
      );

      final controller = BarcodeScanController(
        inventoryManagerRepository: repository,
        productRepository: _FakeProductRepository(
          barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
        ),
      );
      Get.put(controller);

      await tester.pumpWidget(testApp());
      await controller.resolveBarcode('BC-001');
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.productDetails);
      expect(find.text('details-int'), findsOneWidget);
    },
  );

  testWidgets(
    'opens product details directly when resolve returns product data',
    (tester) async {
      final repository = _FakeInventoryManagerRepository(
        resolveHandler: (barcode) async => BarcodeResolveResponse(
          message: 'found',
          exists: true,
          action: 'view_or_update',
          barcode: barcode,
          matchType: 'product',
          data: const ProductModel(id: 1, name: 'Existing Product'),
          variant: null,
        ),
        barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
      );

      final controller = BarcodeScanController(
        inventoryManagerRepository: repository,
        productRepository: _FakeProductRepository(
          barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
        ),
      );
      Get.put(controller);

      await tester.pumpWidget(testApp());
      await controller.resolveBarcode('BC-001');
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.productDetails);
      expect(find.text('details-int'), findsOneWidget);
    },
  );

  testWidgets(
    'fetches product by barcode when resolve says existing product but data is missing',
    (tester) async {
      var lookupCalled = false;
      final repository = _FakeInventoryManagerRepository(
        resolveHandler: (barcode) async => BarcodeResolveResponse(
          message: 'found',
          exists: true,
          action: 'view_or_update',
          barcode: barcode,
          matchType: 'product',
          data: null,
          variant: null,
        ),
        barcodeLookupHandler: (barcode) async {
          lookupCalled = true;
          return const ProductModel(id: 5, name: 'Recovered Product');
        },
      );

      final controller = BarcodeScanController(
        inventoryManagerRepository: repository,
        productRepository: _FakeProductRepository(
          barcodeLookupHandler: (barcode) async => throw UnimplementedError(),
        ),
      );
      Get.put(controller);

      await tester.pumpWidget(testApp());
      await controller.resolveBarcode('BC-001');
      await tester.pumpAndSettle();

      expect(lookupCalled, isTrue);
      expect(Get.currentRoute, AppRoutes.productDetails);
      expect(find.text('details-int'), findsOneWidget);
    },
  );

  testWidgets('returns scanned product result for sales order lookup', (
    tester,
  ) async {
    var lookupCalled = false;
    final repository = _FakeInventoryManagerRepository(
      resolveHandler: (barcode) async => throw UnimplementedError(),
      barcodeLookupHandler: (barcode) async {
        throw UnimplementedError();
      },
    );
    final productRepository = _FakeProductRepository(
      barcodeLookupHandler: (barcode) async {
        lookupCalled = true;
        return const ProductModel(id: 8, name: 'Scanned Product');
      },
    );

    final controller = BarcodeScanController(
      inventoryManagerRepository: repository,
      productRepository: productRepository,
    );
    Get.put(controller);
    controller.scanContext.value = BarcodeScanContext.salesOrderLookup;

    await tester.pumpWidget(testApp());
    await controller.resolveBarcode('BC-001');

    expect(lookupCalled, isTrue);
    expect(controller.errorMessage.value, isNull);
  });
}
