import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';

class OrderProductPickerController extends GetxController {
  OrderProductPickerController({required ProductRepository productRepository})
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
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetchProducts(reset: true);
  }

  Future<void> fetchProducts({required bool reset}) async {
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
      );

      final fetchedProducts = response.data ?? const <ProductModel>[];
      if (reset) {
        products.assignAll(fetchedProducts);
      } else {
        products.addAll(fetchedProducts);
      }

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
      searchQuery.value = '';
      infoMessage.value = null;
      fetchProducts(reset: true);
      return;
    }

    if (trimmed.length < 3) {
      infoMessage.value = 'Type at least 3 characters to search.';
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      searchQuery.value = trimmed;
      infoMessage.value = null;
      fetchProducts(reset: true);
    });
  }

  Future<void> retry() => fetchProducts(reset: true);

  String formatPrice(num? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final threshold = scrollController.position.maxScrollExtent - 200;
    if (scrollController.position.pixels >= threshold) {
      fetchProducts(reset: false);
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
