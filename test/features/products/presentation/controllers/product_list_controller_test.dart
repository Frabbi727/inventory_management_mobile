import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/models/pagination_links_model.dart';
import 'package:inventory_management_sales/core/models/pagination_meta_model.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/products/data/models/product_list_response_model.dart';
import 'package:inventory_management_sales/features/products/data/models/product_model.dart';
import 'package:inventory_management_sales/features/products/data/repositories/product_repository.dart';
import 'package:inventory_management_sales/features/products/presentation/controllers/product_list_controller.dart';

class FakeProductRepository extends ProductRepository {
  FakeProductRepository()
    : super(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final List<(int page, String? query)> calls = [];

  @override
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    String? query,
    bool forceRefresh = false,
  }) async {
    calls.add((page, query));
    return ProductListResponseModel(
      data: [
        ProductModel(
          id: page,
          name: query == null ? 'Product $page' : 'Search $query',
          sku: 'SKU-$page',
          sellingPrice: 50,
          currentStock: 10,
        ),
      ],
      links: PaginationLinksModel(next: page < 2 ? 'next' : null),
      meta: PaginationMetaModel(currentPage: page, lastPage: 2),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('controller fetches products when first loaded', () async {
    final repository = FakeProductRepository();
    final controller = ProductListController(productRepository: repository);

    controller.onInit();
    expect(repository.calls, isEmpty);

    await controller.ensureLoaded();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.calls, [(1, null)]);
    expect(controller.products, isNotEmpty);
    controller.onClose();
  });

  test(
    'product search waits for 3 characters and resets to default below threshold',
    () async {
      final repository = FakeProductRepository();
      final controller = ProductListController(productRepository: repository);

      controller.onInit();
      await controller.ensureLoaded();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.onSearchChanged('mi');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 1);
      expect(repository.calls.last, (1, null));

      controller.onSearchChanged('milk');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 2);
      expect(repository.calls.last, (1, 'milk'));

      await controller.fetchProducts(reset: false);
      expect(repository.calls.last, (2, 'milk'));

      controller.onSearchChanged('mi');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 4);
      expect(repository.calls.last, (1, null));

      controller.onSearchChanged('milk');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 5);
      expect(repository.calls.last, (1, 'milk'));

      controller.clearSearch();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.calls.length, 6);
      expect(repository.calls.last, (1, null));
      controller.onClose();
    },
  );
}
