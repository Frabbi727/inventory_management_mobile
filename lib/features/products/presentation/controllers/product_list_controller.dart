import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductListController extends GetxController {
  ProductListController({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final products = <ProductModel>[].obs;
  final isInitialLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final searchQuery = ''.obs;

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  Timer? _searchDebounce;

  bool get hasActiveSearch => searchQuery.value.isNotEmpty;
  bool get hasErrorState =>
      errorMessage.value != null && products.isEmpty && !isInitialLoading.value;
  bool get hasEmptyState =>
      products.isEmpty &&
      errorMessage.value == null &&
      !isInitialLoading.value &&
      !isSearching.value;

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

    if (reset) {
      isInitialLoading.value = true;
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
        infoMessage.value = requestedQuery.isEmpty
            ? 'No active products found.'
            : 'No products found for "$requestedQuery".';
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

  void onSearchChanged(String value) {
    final trimmed = value.trim();
    errorMessage.value = null;
    _searchDebounce?.cancel();

    if (trimmed.isEmpty) {
      final hadSearch = searchQuery.value.isNotEmpty;
      searchQuery.value = '';
      infoMessage.value = null;
      if (hadSearch || products.isEmpty) {
        unawaited(fetchProducts(reset: true));
      }
      return;
    }

    isSearching.value = true;

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (trimmed == searchQuery.value) {
        isSearching.value = false;
        return;
      }
      searchQuery.value = trimmed;
      infoMessage.value = null;
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
