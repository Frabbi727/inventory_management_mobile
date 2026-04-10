import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/inventory_purchase_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class PurchaseRecordsController extends GetxController {
  PurchaseRecordsController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final scrollController = ScrollController();
  final searchTextController = TextEditingController();
  final purchases = <InventoryPurchaseModel>[].obs;
  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final searchQuery = ''.obs;
  final startDate = RxnString();
  final endDate = RxnString();

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  String _lastIssuedQuery = '';
  bool _pendingReset = false;
  Timer? _searchDebounce;

  bool get hasActiveSearch => searchQuery.value.trim().isNotEmpty;
  bool get hasActiveDateFilter =>
      startDate.value != null || endDate.value != null;
  bool get hasAnyQueryApplied => hasActiveSearch || hasActiveDateFilter;
  bool get showInlineLoader => isRefreshing.value && purchases.isNotEmpty;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasMorePages => _hasNextPage;
  int get activeFilterCount {
    var count = 0;
    if (hasActiveSearch) {
      count++;
    }
    if (hasActiveDateFilter) {
      count++;
    }
    return count;
  }

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
      await fetchPurchases(reset: true);
    }
  }

  Future<void> fetchPurchases({required bool reset}) async {
    final requestedQuery = searchQuery.value.trim();
    final hasExistingItems = purchases.isNotEmpty;

    if (reset) {
      if (isInitialLoading.value || isRefreshing.value) {
        _pendingReset = true;
        return;
      }

      _pendingReset = false;
      isLoadingMore.value = false;
      isInitialLoading.value = !hasExistingItems;
      isRefreshing.value = hasExistingItems;
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
      final response = await _inventoryManagerRepository.fetchPurchases(
        page: pageToLoad,
        query: requestedQuery.isEmpty ? null : requestedQuery,
        startDate: startDate.value,
        endDate: endDate.value,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final fetchedPurchases = response.data ?? const <InventoryPurchaseModel>[];
      if (reset) {
        purchases.assignAll(_deduplicatePurchases(fetchedPurchases));
      } else {
        purchases.assignAll(
          _deduplicatePurchases([...purchases, ...fetchedPurchases]),
        );
      }

      _hasLoadedOnce = true;
      _lastIssuedQuery = requestedQuery;

      final currentPage = response.meta?.currentPage ?? pageToLoad;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      if (purchases.isEmpty) {
        infoMessage.value = hasAnyQueryApplied
            ? 'No purchases matched the current search and date filters.'
            : 'No purchases have been recorded yet.';
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (reset && !hasExistingItems) {
        purchases.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load purchases right now.';
      if (reset && !hasExistingItems) {
        purchases.clear();
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        isInitialLoading.value = false;
        isRefreshing.value = false;
        isLoadingMore.value = false;
        isSearching.value = false;

        if (_pendingReset) {
          _pendingReset = false;
          unawaited(fetchPurchases(reset: true));
        }
      }
    }
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
        unawaited(fetchPurchases(reset: true));
      } else {
        infoMessage.value = purchases.isEmpty ? infoMessage.value : null;
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

      unawaited(fetchPurchases(reset: true));
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
      unawaited(fetchPurchases(reset: true));
    }
  }

  Future<void> pickDateRange(BuildContext context) async {
    final currentRange = selectedDateRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: currentRange,
    );

    if (picked == null) {
      return;
    }

    startDate.value = _formatDateForApi(picked.start);
    endDate.value = _formatDateForApi(picked.end);
    await fetchPurchases(reset: true);
  }

  Future<void> clearDateRange() async {
    if (!hasActiveDateFilter) {
      return;
    }
    startDate.value = null;
    endDate.value = null;
    await fetchPurchases(reset: true);
  }

  Future<void> clearAllCriteria() async {
    final hadSearch = hasActiveSearch || searchTextController.text.isNotEmpty;
    final hadDates = hasActiveDateFilter;

    _searchDebounce?.cancel();
    searchQuery.value = '';
    _lastIssuedQuery = '';
    if (searchTextController.text.isNotEmpty) {
      searchTextController.clear();
    }
    startDate.value = null;
    endDate.value = null;
    isSearching.value = false;

    if (hadSearch || hadDates || purchases.isEmpty) {
      await fetchPurchases(reset: true);
    }
  }

  Future<void> retry() => fetchPurchases(reset: true);

  Future<void> openCreatePurchase() async {
    final result = await Get.toNamed(AppRoutes.inventoryPurchaseCreate);
    if (result != null) {
      await fetchPurchases(reset: true);
    }
  }

  Future<void> openPurchaseEditor(InventoryPurchaseModel purchase) async {
    final purchaseId = purchase.id;
    if (purchaseId == null) {
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.inventoryPurchaseEdit,
      arguments: purchaseId,
    );

    if (result == true) {
      await fetchPurchases(reset: true);
    }
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
      await fetchPurchases(reset: false);
    }
  }

  DateTimeRange? get selectedDateRange {
    final parsedStart = _tryParseDate(startDate.value);
    final parsedEnd = _tryParseDate(endDate.value);
    if (parsedStart == null || parsedEnd == null) {
      return null;
    }
    return DateTimeRange(start: parsedStart, end: parsedEnd);
  }

  String formatDate(String? value) {
    final parsed = _tryParseDate(value);
    if (parsed == null) {
      return value ?? '-';
    }

    final month = _monthLabel(parsed.month);
    return '${parsed.day.toString().padLeft(2, '0')} $month ${parsed.year}';
  }

  String formatCurrency(num? value) {
    final amount = (value ?? 0).toDouble().toStringAsFixed(2);
    return '৳$amount';
  }

  String get dateRangeLabel {
    if (!hasActiveDateFilter) {
      return 'Filter by date';
    }

    final startLabel = formatDate(startDate.value);
    final endLabel = formatDate(endDate.value);
    return '$startLabel - $endLabel';
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    unawaited(loadMoreIfNeeded(scrollController.position));
  }

  List<InventoryPurchaseModel> _deduplicatePurchases(
    List<InventoryPurchaseModel> values,
  ) {
    final seenIds = <int>{};
    final result = <InventoryPurchaseModel>[];

    for (final purchase in values) {
      final id = purchase.id;
      if (id == null) {
        result.add(purchase);
        continue;
      }
      if (seenIds.add(id)) {
        result.add(purchase);
      }
    }

    return result;
  }

  String _formatDateForApi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _monthLabel(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}
