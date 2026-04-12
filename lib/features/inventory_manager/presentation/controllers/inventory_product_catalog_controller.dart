import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../../../products/data/models/product_subcategory_model.dart';
import '../../../products/data/repositories/product_repository.dart';

abstract class InventoryProductCatalogController extends GetxController {
  InventoryProductCatalogController({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final scrollController = ScrollController();
  final searchTextController = TextEditingController();
  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final subcategories = <ProductSubcategoryModel>[].obs;
  final selectedCategoryId = Rxn<int>();
  final selectedSubcategoryId = Rxn<int>();
  final selectedStockStatus = Rxn<ProductStockStatus>();
  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final isCategoriesLoading = false.obs;
  final isSubcategoriesLoading = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final searchQuery = ''.obs;

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  String _lastExecutedQuery = '';
  bool _pendingReset = false;
  Timer? _searchDebounce;

  bool get loadCategoriesOnInit => false;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasActiveSearch => searchQuery.value.isNotEmpty;
  bool get hasActiveCategory => selectedCategoryId.value != null;
  bool get hasActiveSubcategory => selectedSubcategoryId.value != null;
  bool get hasActiveStockStatus => selectedStockStatus.value != null;
  bool get hasActiveFilter =>
      hasActiveSearch ||
      hasActiveCategory ||
      hasActiveSubcategory ||
      hasActiveStockStatus;
  bool get showInlineLoader => isRefreshing.value && products.isNotEmpty;
  bool get hasErrorState =>
      errorMessage.value != null && products.isEmpty && !isInitialLoading.value;
  bool get hasEmptyState =>
      visibleProducts.isEmpty &&
      errorMessage.value == null &&
      !isInitialLoading.value &&
      !isSearching.value;
  bool get isSubcategoryEnabled =>
      selectedCategoryId.value != null && !isSubcategoriesLoading.value;

  List<ProductModel> get visibleProducts {
    final selectedStatus = selectedStockStatus.value;
    if (selectedStatus == null) {
      return products;
    }

    return products
        .where((product) => product.effectiveStockStatus == selectedStatus)
        .toList(growable: false);
  }

  String get emptyStateMessage {
    if (products.isEmpty) {
      return infoMessage.value ??
          buildEmptyMessage(
            searchQuery.value.trim(),
            selectedCategoryId.value,
            selectedSubcategoryId.value,
            selectedStockStatus.value,
          );
    }

    final stockStatus = selectedStockStatus.value;
    if (stockStatus != null) {
      return 'No ${stockStatus.displayLabel.toLowerCase()} products found for the current filters.';
    }

    return 'No products found.';
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    if (loadCategoriesOnInit) {
      unawaited(loadCategories());
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchProducts(reset: true, forceRefresh: forceRefresh);
    }
  }

  Future<void> onTabActivated() => ensureLoaded(forceRefresh: products.isEmpty);

  Future<void> loadCategories() async {
    if (categories.isNotEmpty || isCategoriesLoading.value) {
      return;
    }

    isCategoriesLoading.value = true;
    try {
      final response = await _productRepository.fetchCategories();
      categories.assignAll(response.data ?? const <CategoryModel>[]);
    } catch (_) {
      // Categories are optional; failure should not block product browsing.
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void onCategoryChanged(int? id) {
    if (selectedCategoryId.value == id) {
      return;
    }

    selectedCategoryId.value = id;
    selectedSubcategoryId.value = null;
    unawaited(_handleCategoryChange(id));
  }

  void clearCategory() {
    if (selectedCategoryId.value == null) {
      return;
    }

    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    subcategories.clear();
    unawaited(fetchProducts(reset: true));
  }

  Future<void> loadSubcategories(int? categoryId) async {
    subcategories.clear();
    if (categoryId == null) {
      return;
    }

    isSubcategoriesLoading.value = true;
    try {
      final fetched = await _productRepository.fetchSubcategories(
        categoryId: categoryId,
      );
      subcategories.assignAll(fetched);
    } catch (_) {
      subcategories.clear();
    } finally {
      isSubcategoriesLoading.value = false;
    }
  }

  void onSubcategoryChanged(int? id) {
    if (selectedSubcategoryId.value == id) {
      return;
    }

    selectedSubcategoryId.value = id;
    unawaited(fetchProducts(reset: true));
  }

  void clearSubcategory() {
    if (selectedSubcategoryId.value == null) {
      return;
    }

    selectedSubcategoryId.value = null;
    unawaited(fetchProducts(reset: true));
  }

  void onStockStatusChanged(ProductStockStatus? status) {
    if (selectedStockStatus.value == status) {
      return;
    }

    selectedStockStatus.value = status;
  }

  Future<void> applyFilters({
    int? categoryId,
    int? subcategoryId,
    ProductStockStatus? stockStatus,
  }) async {
    final categoryChanged = selectedCategoryId.value != categoryId;

    selectedCategoryId.value = categoryId;
    selectedStockStatus.value = stockStatus;

    if (categoryChanged) {
      if (categoryId == null) {
        subcategories.clear();
      } else {
        await loadSubcategories(categoryId);
      }
    }

    selectedSubcategoryId.value = subcategoryId;
    await fetchProducts(reset: true);
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    final hadSearch =
        searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
    final hadCategory = selectedCategoryId.value != null;
    final hadSubcategory = selectedSubcategoryId.value != null;
    final hadStockStatus = selectedStockStatus.value != null;
    searchQuery.value = '';
    if (searchTextController.text.isNotEmpty) {
      searchTextController.clear();
    }
    infoMessage.value = null;
    isSearching.value = false;
    _lastExecutedQuery = '';
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    selectedStockStatus.value = null;
    subcategories.clear();

    if (hadSearch || hadCategory || hadSubcategory || products.isEmpty) {
      unawaited(fetchProducts(reset: true));
    } else if (hadStockStatus) {
      products.refresh();
    }
  }

  Future<void> retry() => fetchProducts(reset: true, forceRefresh: true);

  Future<void> fetchProducts({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    final requestedQuery = searchQuery.value.trim();
    final requestedCategory = selectedCategoryId.value;
    final requestedSubcategory = selectedSubcategoryId.value;
    final hasExistingItems = products.isNotEmpty;

    if (reset) {
      if (isInitialLoading.value || isRefreshing.value) {
        _pendingReset = true;
        return;
      }

      _pendingReset = false;
      isInitialLoading.value = !hasExistingItems;
      isRefreshing.value = hasExistingItems;
      isSearching.value = requestedQuery.isNotEmpty;
      isLoadingMore.value = false;
      errorMessage.value = null;
      _currentPage = 1;
      _hasNextPage = false;
      _requestGeneration++;
    } else {
      if (isLoadingMore.value ||
          !_hasNextPage ||
          isInitialLoading.value ||
          isRefreshing.value) {
        return;
      }
      isLoadingMore.value = true;
    }

    final requestGeneration = _requestGeneration;
    final pageToLoad = _currentPage;

    try {
      final response = await _productRepository.fetchProducts(
        page: pageToLoad,
        query: requestedQuery.isEmpty ? null : requestedQuery,
        categoryId: requestedCategory,
        subcategoryId: requestedSubcategory,
        forceRefresh: forceRefresh,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final fetchedProducts = response.data ?? const <ProductModel>[];
      if (reset) {
        products.assignAll(_deduplicateProducts(fetchedProducts));
      } else {
        products.assignAll(
          _deduplicateProducts([...products, ...fetchedProducts]),
        );
      }
      _hasLoadedOnce = true;

      final currentPage = response.meta?.currentPage ?? pageToLoad;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;
      infoMessage.value = products.isEmpty
          ? buildEmptyMessage(
              requestedQuery,
              requestedCategory,
              requestedSubcategory,
              selectedStockStatus.value,
            )
          : null;
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (reset && !hasExistingItems) {
        products.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load products right now.';
      if (reset && !hasExistingItems) {
        products.clear();
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        isInitialLoading.value = false;
        isRefreshing.value = false;
        isLoadingMore.value = false;
        isSearching.value = false;

        if (_pendingReset) {
          _pendingReset = false;
          unawaited(fetchProducts(reset: true));
        }
      }
    }
  }

  void onSearchChanged(String value) {
    final trimmed = value.trim();
    errorMessage.value = null;
    _searchDebounce?.cancel();

    if (trimmed.isEmpty) {
      final hadSearch =
          searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
      searchQuery.value = '';
      if (searchTextController.text.isNotEmpty) {
        searchTextController.clear();
      }
      infoMessage.value = null;
      isSearching.value = false;
      _lastExecutedQuery = '';
      if (hadSearch || products.isEmpty) {
        unawaited(fetchProducts(reset: true));
      }
      return;
    }

    if (trimmed.length < 3) {
      final hadActiveSearch =
          searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
      searchQuery.value = '';
      infoMessage.value = null;
      isSearching.value = false;
      if (hadActiveSearch) {
        _lastExecutedQuery = '';
        unawaited(fetchProducts(reset: true));
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (trimmed == _lastExecutedQuery) {
        isSearching.value = false;
        return;
      }

      searchQuery.value = trimmed;
      infoMessage.value = null;
      _lastExecutedQuery = trimmed;
      unawaited(fetchProducts(reset: true));
    });
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty && searchTextController.text.isEmpty) {
      return;
    }

    _searchDebounce?.cancel();
    searchQuery.value = '';
    if (searchTextController.text.isNotEmpty) {
      searchTextController.clear();
    }
    infoMessage.value = null;
    isSearching.value = false;
    _lastExecutedQuery = '';
    unawaited(fetchProducts(reset: true));
  }

  Future<void> loadMoreIfNeeded(ScrollMetrics metrics) async {
    if (isInitialLoading.value ||
        isRefreshing.value ||
        isLoadingMore.value ||
        !_hasNextPage) {
      return;
    }

    final remainingScroll = metrics.maxScrollExtent - metrics.pixels;
    if (remainingScroll <= 240) {
      await fetchProducts(reset: false);
    }
  }

  String buildEmptyMessage(
    String query,
    int? categoryId,
    int? subcategoryId,
    ProductStockStatus? stockStatus,
  );

  Future<void> _handleCategoryChange(int? id) async {
    await loadSubcategories(id);
    await fetchProducts(reset: true);
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    unawaited(loadMoreIfNeeded(scrollController.position));
  }

  List<ProductModel> _deduplicateProducts(List<ProductModel> items) {
    final seenKeys = <String>{};
    final deduplicated = <ProductModel>[];

    for (final product in items) {
      final key =
          '${product.id ?? product.barcode ?? product.sku ?? product.name}';
      if (seenKeys.add(key)) {
        deduplicated.add(product);
      }
    }

    return deduplicated;
  }
}
