import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/category_response_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_subcategory_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductListController extends GetxController {
  ProductListController({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final subcategories = <ProductSubcategoryModel>[].obs;
  final selectedCategoryId = Rxn<int>();
  final selectedSubcategoryId = Rxn<int>();
  final isInitialLoading = false.obs;
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
  Timer? _searchDebounce;

  bool get hasActiveSearch => searchQuery.value.isNotEmpty;
  bool get hasActiveCategory => selectedCategoryId.value != null;
  bool get hasActiveSubcategory => selectedSubcategoryId.value != null;
  bool get hasActiveFilter =>
      hasActiveSearch || hasActiveCategory || hasActiveSubcategory;
  bool get hasErrorState =>
      errorMessage.value != null && products.isEmpty && !isInitialLoading.value;
  bool get hasEmptyState =>
      products.isEmpty &&
      errorMessage.value == null &&
      !isInitialLoading.value &&
      !isSearching.value;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (categories.isNotEmpty || isCategoriesLoading.value) return;
    isCategoriesLoading.value = true;
    try {
      final response = await _productRepository.fetchCategories();
      categories.assignAll(response.data ?? const <CategoryModel>[]);
    } catch (_) {
      // Categories are optional; failure is non-fatal.
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void onCategoryChanged(int? id) {
    if (selectedCategoryId.value == id) return;
    selectedCategoryId.value = id;
    selectedSubcategoryId.value = null;
    subcategories.clear();
    if (id != null) {
      unawaited(loadSubcategories(categoryId: id));
    }
    unawaited(fetchProducts(reset: true));
  }

  void clearCategory() {
    if (selectedCategoryId.value == null) return;
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    subcategories.clear();
    unawaited(fetchProducts(reset: true));
  }

  void onSubcategoryChanged(int? id) {
    if (selectedSubcategoryId.value == id) return;
    selectedSubcategoryId.value = id;
    unawaited(fetchProducts(reset: true));
  }

  void clearSubcategory() {
    if (selectedSubcategoryId.value == null) return;
    selectedSubcategoryId.value = null;
    unawaited(fetchProducts(reset: true));
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    final hadSearch = searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
    final hadCategory = selectedCategoryId.value != null;
    final hadSubcategory = selectedSubcategoryId.value != null;
    searchQuery.value = '';
    infoMessage.value = null;
    isSearching.value = false;
    _lastExecutedQuery = '';
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    subcategories.clear();
    if (hadSearch || hadCategory || hadSubcategory || products.isEmpty) {
      unawaited(fetchProducts(reset: true));
    }
  }

  Future<void> loadSubcategories({required int categoryId}) async {
    if (isSubcategoriesLoading.value) return;
    isSubcategoriesLoading.value = true;
    try {
      final response = await _productRepository.fetchSubcategories(
        categoryId: categoryId,
      );
      if (selectedCategoryId.value == categoryId) {
        subcategories.assignAll(response);
      }
    } catch (_) {
      if (selectedCategoryId.value == categoryId) {
        subcategories.clear();
      }
    } finally {
      if (selectedCategoryId.value == categoryId ||
          selectedCategoryId.value == null) {
        isSubcategoriesLoading.value = false;
      }
    }
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchProducts(reset: true, forceRefresh: forceRefresh);
    }
  }

  Future<void> fetchProducts({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    final requestedQuery = searchQuery.value.trim();
    final requestedCategory = selectedCategoryId.value;
    final requestedSubcategory = selectedSubcategoryId.value;
    final hasExistingItems = products.isNotEmpty;

    if (reset) {
      isInitialLoading.value = !hasExistingItems;
      isSearching.value = requestedQuery.isNotEmpty;
      errorMessage.value = null;
      _currentPage = 1;
      _hasNextPage = false;
      _requestGeneration++;
    } else {
      if (isLoadingMore.value || !_hasNextPage || isInitialLoading.value) {
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

      if (products.isEmpty) {
        infoMessage.value = _buildEmptyMessage(
          requestedQuery,
          requestedCategory,
          requestedSubcategory,
        );
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (reset) {
        products.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load products right now.';
      if (reset) {
        products.clear();
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        isInitialLoading.value = false;
        isLoadingMore.value = false;
        isSearching.value = false;
      }
    }
  }

  String _buildEmptyMessage(
    String query,
    int? categoryId,
    int? subcategoryId,
  ) {
    final categoryName = categoryId != null
        ? categories.firstWhereOrNull((c) => c.id == categoryId)?.name
        : null;
    final subcategoryName = subcategoryId != null
        ? subcategories.firstWhereOrNull((s) => s.id == subcategoryId)?.name
        : null;

    if (query.isNotEmpty && categoryName != null && subcategoryName != null) {
      return 'No products found for "$query" in $categoryName / $subcategoryName.';
    }
    if (query.isNotEmpty && categoryName != null) {
      return 'No products found for "$query" in $categoryName.';
    }
    if (query.isNotEmpty) {
      return 'No products found for "$query".';
    }
    if (categoryName != null && subcategoryName != null) {
      return 'No products found in $categoryName / $subcategoryName.';
    }
    if (categoryName != null) {
      return 'No products found in $categoryName.';
    }
    return 'No active products found.';
  }

  void onSearchChanged(String value) {
    final trimmed = value.trim();
    errorMessage.value = null;
    _searchDebounce?.cancel();

    if (trimmed.isEmpty) {
      final hadSearch =
          searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
      searchQuery.value = '';
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
    if (searchQuery.value.isEmpty) {
      return;
    }

    _searchDebounce?.cancel();
    searchQuery.value = '';
    infoMessage.value = null;
    isSearching.value = false;
    _lastExecutedQuery = '';
    unawaited(fetchProducts(reset: true));
  }

  Future<void> retry() => ensureLoaded(forceRefresh: true);

  Future<void> loadMoreIfNeeded(ScrollMetrics metrics) async {
    if (isInitialLoading.value || isLoadingMore.value || !_hasNextPage) {
      return;
    }

    final remainingScroll = metrics.maxScrollExtent - metrics.pixels;
    if (remainingScroll <= 240) {
      await fetchProducts(reset: false);
    }
  }

  List<ProductModel> _deduplicateProducts(List<ProductModel> items) {
    final uniqueById = <int?, ProductModel>{};
    final withoutId = <ProductModel>[];

    for (final product in items) {
      if (product.id == null) {
        if (!withoutId.any(
          (item) =>
              item.name == product.name &&
              item.sku == product.sku &&
              item.sellingPrice == product.sellingPrice,
        )) {
          withoutId.add(product);
        }
        continue;
      }

      uniqueById[product.id] = product;
    }

    return [...uniqueById.values, ...withoutId];
  }

  String formatPrice(num? value) {
    if (value == null) {
      return '-';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
