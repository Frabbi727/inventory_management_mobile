import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductListController extends GetxController {
  ProductListController({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final products = <ProductModel>[].obs;
  final isInitialLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final searchQuery = ''.obs;

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasLoadedOnce = false;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
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
    if (reset) {
      isInitialLoading.value = true;
      errorMessage.value = null;
      _currentPage = 1;
      _hasNextPage = false;
    } else {
      if (isLoadingMore.value || !_hasNextPage || isInitialLoading.value) {
        return;
      }
      isLoadingMore.value = true;
    }

    try {
      final response = await _productRepository.fetchProducts(
        page: _currentPage,
        query: searchQuery.value.isEmpty ? null : searchQuery.value,
        forceRefresh: forceRefresh,
      );

      final fetchedProducts = response.data ?? const <ProductModel>[];
      if (reset) {
        products.assignAll(fetchedProducts);
      } else {
        products.addAll(fetchedProducts);
      }
      _hasLoadedOnce = true;

      final currentPage = response.meta?.currentPage ?? _currentPage;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      if (products.isEmpty) {
        infoMessage.value = searchQuery.value.isEmpty
            ? 'No active products found.'
            : 'No products found for "${searchQuery.value}".';
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (reset) {
        products.clear();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load products right now.';
      if (reset) {
        products.clear();
      }
    } finally {
      isInitialLoading.value = false;
      isLoadingMore.value = false;
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
        fetchProducts(reset: true);
      }
      return;
    }

    if (trimmed.length < 3) {
      infoMessage.value = 'Type at least 3 characters to search.';
      if (searchQuery.value.isNotEmpty) {
        searchQuery.value = '';
        fetchProducts(reset: true);
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      searchQuery.value = trimmed;
      infoMessage.value = null;
      fetchProducts(reset: true);
    });
  }

  Future<void> retry() => ensureLoaded(forceRefresh: true);

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final threshold = scrollController.position.maxScrollExtent - 200;
    if (scrollController.position.pixels >= threshold) {
      fetchProducts(reset: false);
    }
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
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
