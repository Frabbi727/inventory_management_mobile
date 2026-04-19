import 'package:flutter_test/flutter_test.dart';
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
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_stock_status.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';

class FakeInventoryManagerRepository extends InventoryManagerRepository {
  FakeInventoryManagerRepository()
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
  String? lastQuery;
  int? lastPage;
  InventoryDashboardResponseModel dashboardResponse =
      const InventoryDashboardResponseModel(
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
  InventoryProductsResponseModel productsResponse =
      InventoryProductsResponseModel(
        success: true,
        data: InventoryProductsResponseDataModel(
          products: InventoryProductsPageModel(
            data: const [
              ProductModel(
                id: 12,
                name: 'Milk Pack',
                sku: 'MILK-001',
                currentStock: 0,
                minimumStockAlert: 5,
                status: 'active',
              ),
            ],
            currentPage: 1,
            perPage: 10,
            total: 1,
            lastPage: 1,
          ),
        ),
      );
  Object? error;

  @override
  Future<InventoryDashboardResponseModel> fetchInventoryDashboard() async {
    dashboardCallCount++;
    if (error != null) {
      throw error!;
    }
    return dashboardResponse;
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
    lastQuery = query;
    lastPage = page;
    if (error != null) {
      throw error!;
    }
    return productsResponse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensureLoaded populates summary and products from inventory APIs', () async {
    final repository = FakeInventoryManagerRepository();
    final controller = InventoryProductsController(
      inventoryManagerRepository: repository,
    );

    await controller.ensureLoaded();

    expect(repository.dashboardCallCount, 1);
    expect(repository.productsCallCount, 1);
    expect(repository.lastStockFilter, 'all');
    expect(controller.summary.value?.allCount, 120);
    expect(controller.products.single.name, 'Milk Pack');
    expect(controller.totalProducts.value, 1);
  });

  test('applyStockFilter reloads products with chosen stock filter', () async {
    final repository = FakeInventoryManagerRepository();
    final controller = InventoryProductsController(
      inventoryManagerRepository: repository,
    );

    await controller.ensureLoaded();
    await controller.applyStockFilter(ProductStockStatus.lowStock);

    expect(repository.dashboardCallCount, 2);
    expect(repository.productsCallCount, 2);
    expect(repository.lastStockFilter, 'low_stock');
    expect(
      controller.selectedStockStatus.value,
      ProductStockStatus.lowStock,
    );
  });

  test('null summary and empty list show empty state message', () async {
    final repository = FakeInventoryManagerRepository()
      ..dashboardResponse = const InventoryDashboardResponseModel(
        success: true,
        data: InventoryDashboardDataModel(summary: null),
      )
      ..productsResponse = const InventoryProductsResponseModel(
        success: true,
        data: InventoryProductsResponseDataModel(
          products: InventoryProductsPageModel(
            data: <ProductModel>[],
            currentPage: 1,
            perPage: 10,
            total: 0,
            lastPage: 1,
          ),
        ),
      );
    final controller = InventoryProductsController(
      inventoryManagerRepository: repository,
    );

    await controller.ensureLoaded();

    expect(controller.summary.value, isNull);
    expect(controller.products, isEmpty);
    expect(
      controller.infoMessage.value,
      'No inventory summary is available right now.',
    );
  });

  test('api error exposes retryable error state', () async {
    final repository = FakeInventoryManagerRepository()
      ..error = Exception('network failed');
    final controller = InventoryProductsController(
      inventoryManagerRepository: repository,
    );

    await controller.ensureLoaded();

    expect(controller.summary.value, isNull);
    expect(controller.products, isEmpty);
    expect(controller.errorMessage.value, 'Unable to load products right now.');
  });
}
