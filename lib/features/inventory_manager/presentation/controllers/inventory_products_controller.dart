import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import '../models/barcode_scan_models.dart';
import '../models/product_form_args.dart';
import '../../data/models/inventory_dashboard_summary_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class InventoryProductsController extends GetxController {
  InventoryProductsController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  static const _pageSize = 10;

  final InventoryManagerRepository _inventoryManagerRepository;

  final scrollController = ScrollController();
  final searchTextController = TextEditingController();
  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final summary = Rxn<InventoryDashboardSummaryModel>();
  final products = <ProductModel>[].obs;
  final selectedStockStatus = Rxn<ProductStockStatus>();
  final searchQuery = ''.obs;
  final totalProducts = 0.obs;

  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _pendingReset = false;
  String _lastIssuedQuery = '';
  Timer? _searchDebounce;

  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasActiveSearch => searchQuery.value.isNotEmpty;
  bool get hasActiveFilter => selectedStockStatus.value != null;
  bool get showInlineLoader =>
      isRefreshing.value && (summary.value != null || products.isNotEmpty);
  bool get hasErrorState =>
      errorMessage.value != null &&
      summary.value == null &&
      products.isEmpty &&
      !isInitialLoading.value;
  bool get hasEmptyState =>
      products.isEmpty &&
      errorMessage.value == null &&
      !isInitialLoading.value &&
      !isSearching.value;

  String get selectedFilterLabel =>
      selectedStockStatus.value?.displayLabel ?? 'All Products';

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    ensureLoaded();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchInventoryProducts(reset: true);
    }
  }

  Future<void> onTabActivated() => ensureLoaded(forceRefresh: true);

  Future<void> retry() => fetchInventoryProducts(reset: true);

  @override
  Future<void> refresh() => fetchInventoryProducts(reset: true);

  Future<void> fetchInventoryProducts({required bool reset}) async {
    final requestedQuery = searchQuery.value.trim();
    final hasExistingData = summary.value != null || products.isNotEmpty;

    if (reset) {
      if (isInitialLoading.value || isRefreshing.value) {
        _pendingReset = true;
        return;
      }

      _pendingReset = false;
      isLoadingMore.value = false;
      isInitialLoading.value = !hasExistingData;
      isRefreshing.value = hasExistingData;
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
      if (reset) {
        final dashboardResponse = await _inventoryManagerRepository
            .fetchInventoryDashboard();
        if (requestGeneration != _requestGeneration) {
          return;
        }
        summary.value = dashboardResponse.data?.summary;
      }

      final response = await _inventoryManagerRepository.fetchInventoryProducts(
        stockFilter: _stockFilterApiValue(selectedStockStatus.value),
        query: requestedQuery.isEmpty ? null : requestedQuery,
        page: pageToLoad,
        perPage: _pageSize,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final page = response.data?.products;
      final fetchedProducts = page?.data ?? const <ProductModel>[];
      if (reset) {
        products.assignAll(_deduplicateProducts(fetchedProducts));
      } else {
        products.assignAll(
          _deduplicateProducts([...products, ...fetchedProducts]),
        );
      }

      totalProducts.value = page?.total ?? products.length;
      final currentPage = page?.currentPage ?? pageToLoad;
      final lastPage = page?.lastPage ?? currentPage;
      _hasNextPage = currentPage < lastPage;
      _currentPage = currentPage + 1;
      _lastIssuedQuery = requestedQuery;
      _hasLoadedOnce = true;

      if (summary.value == null && products.isEmpty) {
        infoMessage.value = 'No inventory summary is available right now.';
      } else if (products.isEmpty) {
        infoMessage.value = buildEmptyMessage();
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }

      errorMessage.value = error.message;
      if (reset && !hasExistingData) {
        summary.value = null;
        products.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }

      errorMessage.value = 'Unable to load products right now.';
      if (reset && !hasExistingData) {
        summary.value = null;
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
          unawaited(fetchInventoryProducts(reset: true));
        }
      }
    }
  }

  Future<void> applyStockFilter(ProductStockStatus? status) async {
    if (selectedStockStatus.value == status) {
      return;
    }
    selectedStockStatus.value = status;
    await fetchInventoryProducts(reset: true);
  }

  void onSearchChanged(String value) {
    final trimmed = value.trim();
    searchQuery.value = trimmed;
    errorMessage.value = null;
    _searchDebounce?.cancel();

    if (trimmed.isEmpty) {
      if (searchTextController.text.isNotEmpty) {
        searchTextController.clear();
      }
      isSearching.value = false;
      if (_lastIssuedQuery.isNotEmpty) {
        _lastIssuedQuery = '';
        unawaited(fetchInventoryProducts(reset: true));
      }
      return;
    }

    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final latestQuery = searchQuery.value.trim();
      if (latestQuery == _lastIssuedQuery) {
        isSearching.value = false;
        return;
      }
      unawaited(fetchInventoryProducts(reset: true));
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
    isSearching.value = false;
    if (_lastIssuedQuery.isNotEmpty) {
      _lastIssuedQuery = '';
      unawaited(fetchInventoryProducts(reset: true));
    }
  }

  Future<void> clearFilters() async {
    if (!hasActiveFilter) {
      return;
    }
    selectedStockStatus.value = null;
    await fetchInventoryProducts(reset: true);
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
      await fetchInventoryProducts(reset: false);
    }
  }

  void openScan() {
    Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.productLookup,
      ),
    );
  }

  void openManualCreate() {
    Get.toNamed(
      AppRoutes.inventoryProductForm,
      arguments: const ProductFormArgs.create(source: ProductFormSource.manual),
    );
  }

  Future<void> openDetails(ProductModel product) async {
    await Get.toNamed(AppRoutes.productDetails, arguments: product);
  }

  int countForStatus(ProductStockStatus? status) {
    final currentSummary = summary.value;
    if (currentSummary == null) {
      return 0;
    }

    return switch (status) {
      null => currentSummary.allCount ?? currentSummary.totalActiveProducts ?? 0,
      ProductStockStatus.inStock => currentSummary.inStockCount ?? 0,
      ProductStockStatus.lowStock => currentSummary.lowStockCount ?? 0,
      ProductStockStatus.outOfStock => currentSummary.outOfStockCount ?? 0,
    };
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '৳0';
    }
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }
    return '৳${value.toStringAsFixed(2)}';
  }

  String buildEmptyMessage() {
    final label = selectedFilterLabel.toLowerCase();
    if (hasActiveSearch) {
      return 'No $label matched "${searchQuery.value}".';
    }
    return 'No $label available right now.';
  }

  String _stockFilterApiValue(ProductStockStatus? status) {
    return switch (status) {
      null => 'all',
      ProductStockStatus.inStock => 'in_stock',
      ProductStockStatus.lowStock => 'low_stock',
      ProductStockStatus.outOfStock => 'out_of_stock',
    };
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    unawaited(loadMoreIfNeeded(scrollController.position));
  }

  List<ProductModel> _deduplicateProducts(List<ProductModel> values) {
    final seenIds = <int>{};
    final result = <ProductModel>[];

    for (final product in values) {
      final id = product.id;
      if (id == null) {
        result.add(product);
        continue;
      }
      if (seenIds.add(id)) {
        result.add(product);
      }
    }

    return result;
  }
}
