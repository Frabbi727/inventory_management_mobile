import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/models/pagination_links_model.dart';
import 'package:b2b_inventory_management/core/models/pagination_meta_model.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/products/data/models/category_response_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_list_response_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_model.dart';
import 'package:b2b_inventory_management/features/products/data/models/product_subcategory_model.dart';
import 'package:b2b_inventory_management/features/products/data/repositories/product_repository.dart';
import 'package:b2b_inventory_management/features/products/presentation/controllers/product_list_controller.dart';

class FakeProductRepository extends ProductRepository {
  FakeProductRepository()
    : super(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final List<({int page, String? query, int? categoryId, int? subcategoryId})>
  calls = [];
  final List<int?> subcategoryRequests = [];

  @override
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    String? query,
    bool forceRefresh = false,
    int? categoryId,
    int? subcategoryId,
  }) async {
    calls.add((
      page: page,
      query: query,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    ));
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

  @override
  Future<CategoryResponseModel> fetchCategories() async {
    return const CategoryResponseModel(
      data: [
        CategoryModel(id: 1, name: 'Dairy'),
        CategoryModel(id: 2, name: 'Snacks'),
      ],
    );
  }

  @override
  Future<List<ProductSubcategoryModel>> fetchSubcategories({
    int? categoryId,
  }) async {
    subcategoryRequests.add(categoryId);
    if (categoryId == 1) {
      return const [
        ProductSubcategoryModel(id: 11, name: 'Milk', categoryId: 1),
        ProductSubcategoryModel(id: 12, name: 'Yogurt', categoryId: 1),
      ];
    }
    if (categoryId == 2) {
      return const [
        ProductSubcategoryModel(id: 21, name: 'Biscuits', categoryId: 2),
      ];
    }
    return const [];
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

    expect(
      repository.calls,
      [(page: 1, query: null, categoryId: null, subcategoryId: null)],
    );
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
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: null, subcategoryId: null),
      );

      controller.onSearchChanged('milk');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 2);
      expect(
        repository.calls.last,
        (page: 1, query: 'milk', categoryId: null, subcategoryId: null),
      );

      await controller.fetchProducts(reset: false);
      expect(
        repository.calls.last,
        (page: 2, query: 'milk', categoryId: null, subcategoryId: null),
      );

      controller.onSearchChanged('mi');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 4);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: null, subcategoryId: null),
      );

      controller.onSearchChanged('milk');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls.length, 5);
      expect(
        repository.calls.last,
        (page: 1, query: 'milk', categoryId: null, subcategoryId: null),
      );

      controller.clearSearch();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.calls.length, 6);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: null, subcategoryId: null),
      );
      controller.onClose();
    },
  );

  test(
    'category and subcategory filters update requests and clear together',
    () async {
      final repository = FakeProductRepository();
      final controller = ProductListController(productRepository: repository);

      controller.onInit();
      await controller.ensureLoaded();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      controller.onCategoryChanged(1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.selectedCategoryId.value, 1);
      expect(controller.selectedSubcategoryId.value, isNull);
      expect(repository.subcategoryRequests, [1]);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: 1, subcategoryId: null),
      );

      controller.onSubcategoryChanged(11);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.selectedSubcategoryId.value, 11);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: 1, subcategoryId: 11),
      );

      controller.onCategoryChanged(2);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.selectedCategoryId.value, 2);
      expect(controller.selectedSubcategoryId.value, isNull);
      expect(repository.subcategoryRequests, [1, 2]);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: 2, subcategoryId: null),
      );

      controller.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.selectedCategoryId.value, isNull);
      expect(controller.selectedSubcategoryId.value, isNull);
      expect(controller.searchQuery.value, isEmpty);
      expect(
        repository.calls.last,
        (page: 1, query: null, categoryId: null, subcategoryId: null),
      );
      controller.onClose();
    },
  );
}
