import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_dashboard_data_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_dashboard_response_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_dashboard_summary_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_products_page_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_products_response_data_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/models/inventory_products_response_model.dart';
import 'package:b2b_inventory_management/features/inventory_manager/data/repositories/inventory_manager_repository.dart';
import 'package:b2b_inventory_management/features/inventory_manager/presentation/controllers/inventory_products_controller.dart';
import 'package:b2b_inventory_management/features/inventory_manager/presentation/pages/inventory_products_page.dart';
import 'package:b2b_inventory_management/features/inventory_manager/presentation/widgets/inventory_bottom_navigation.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_stock_status.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';

class FakeInventoryProductsRepository extends InventoryManagerRepository {
  FakeInventoryProductsRepository()
    : super(
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

  int dashboardCallCount = 0;
  int productsCallCount = 0;
  String? lastStockFilter;
  final List<int> requestedPages = <int>[];
  Map<int, InventoryProductsResponseModel> pagedProductsResponses =
      <int, InventoryProductsResponseModel>{};
  Completer<InventoryProductsResponseModel>? pendingProductsResponse;

  @override
  Future<InventoryDashboardResponseModel> fetchInventoryDashboard() async {
    dashboardCallCount++;
    return const InventoryDashboardResponseModel(
      success: true,
      data: InventoryDashboardDataModel(
        summary: InventoryDashboardSummaryModel(
          totalActiveProducts: 120,
          allCount: 120,
          lowStockCount: 8,
          outOfStockCount: 3,
          inStockCount: 109,
          productsAddedToday: 4,
          purchasesCreatedToday: 2,
          purchaseValueToday: 5400,
        ),
      ),
    );
  }

  @override
  Future<InventoryProductsResponseModel> fetchInventoryProducts({
    required String stockFilter,
    String? query,
    int page = 1,
    int perPage = 10,
  }) async {
    productsCallCount++;
    lastStockFilter = stockFilter;
    requestedPages.add(page);

    final pagedResponse = pagedProductsResponses[page];
    if (pagedResponse != null) {
      return pagedResponse;
    }

    final pendingResponse = pendingProductsResponse;
    if (pendingResponse != null) {
      return pendingResponse.future;
    }

    final product = switch (stockFilter) {
      'low_stock' => const ProductModel(
        id: 22,
        name: 'Low Stock Oil',
        sku: 'OIL-002',
        currentStock: 2,
        minimumStockAlert: 5,
        stockStatus: ProductStockStatus.lowStock,
        status: 'active',
      ),
      _ => const ProductModel(
        id: 12,
        name: 'Milk Pack',
        sku: 'MILK-001',
        currentStock: 0,
        minimumStockAlert: 5,
        stockStatus: ProductStockStatus.outOfStock,
        status: 'active',
      ),
    };

    return InventoryProductsResponseModel(
      success: true,
      data: InventoryProductsResponseDataModel(
        products: InventoryProductsPageModel(
          data: [product],
          currentPage: 1,
          perPage: 10,
          total: 1,
          lastPage: 1,
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('inventory products page renders summary metrics and list', (
    WidgetTester tester,
  ) async {
    final repository = FakeInventoryProductsRepository();
    Get.put<InventoryProductsController>(
      InventoryProductsController(inventoryManagerRepository: repository),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: InventoryProductsPage())),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('All Products'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Milk Pack'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk Pack'), findsOneWidget);
    expect(repository.dashboardCallCount, 1);
    expect(repository.productsCallCount, 1);
    expect(repository.lastStockFilter, 'all');
  });

  testWidgets('tapping summary card reloads list with selected filter', (
    WidgetTester tester,
  ) async {
    final repository = FakeInventoryProductsRepository();
    Get.put<InventoryProductsController>(
      InventoryProductsController(inventoryManagerRepository: repository),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: InventoryProductsPage())),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Low Stock').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low Stock').first);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Low Stock Oil'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(repository.lastStockFilter, 'low_stock');
    expect(find.text('Low Stock Oil'), findsOneWidget);
  });

  testWidgets('inventory bottom navigation no longer shows stock tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: InventoryBottomNavigation(
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Purchases'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Stock'), findsNothing);
  });

  testWidgets('inventory products page shows footer spinner while loading more', (
    WidgetTester tester,
  ) async {
    final repository = FakeInventoryProductsRepository()
      ..pagedProductsResponses = <int, InventoryProductsResponseModel>{
        1: InventoryProductsResponseModel(
          success: true,
          data: InventoryProductsResponseDataModel(
            products: InventoryProductsPageModel(
              data: List<ProductModel>.generate(
                10,
                (index) => ProductModel(
                  id: index + 1,
                  name: 'Product ${index + 1}',
                  status: 'active',
                ),
              ),
              currentPage: 1,
              perPage: 10,
              total: 15,
              lastPage: 2,
            ),
          ),
        ),
      };
    Get.put<InventoryProductsController>(
      InventoryProductsController(inventoryManagerRepository: repository),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: InventoryProductsPage())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final controller = Get.find<InventoryProductsController>();
    final pendingResponse = Completer<InventoryProductsResponseModel>();
    repository.pendingProductsResponse = pendingResponse;

    controller.loadMoreIfNeeded(
      FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: 900,
        viewportDimension: 500,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
    );

    await tester.pump();

    expect(controller.isLoadingMore.value, isTrue);

    pendingResponse.complete(
      InventoryProductsResponseModel(
        success: true,
        data: InventoryProductsResponseDataModel(
          products: InventoryProductsPageModel(
            data: List<ProductModel>.generate(
              5,
              (index) => ProductModel(
                id: index + 11,
                name: 'Product ${index + 11}',
                status: 'active',
              ),
            ),
            currentPage: 2,
            perPage: 10,
            total: 15,
            lastPage: 2,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.products.length, 15);
    expect(controller.isLoadingMore.value, isFalse);
  });
}
