import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../../../cart_orders/data/repositories/order_repository.dart';

class InvoiceController extends GetxController {
  InvoiceController({required OrderRepository orderRepository})
    : _orderRepository = orderRepository;

  final OrderRepository _orderRepository;

  final scrollController = ScrollController();
  final searchTextController = TextEditingController();
  final orders = <OrderModel>[].obs;
  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final searchQuery = ''.obs;
  final selectedCustomerId = RxnInt();
  final startDate = RxnString();
  final endDate = RxnString();
  final activeStatusTab = 'draft'.obs;

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  String _lastIssuedQuery = '';
  bool _pendingReset = false;
  Timer? _searchDebounce;

  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasMorePages => _hasNextPage;
  bool get hasActiveFilters =>
      selectedCustomerId.value != null ||
      startDate.value != null ||
      endDate.value != null;
  bool get hasAnyQueryApplied =>
      searchQuery.value.trim().isNotEmpty || hasActiveFilters;
  bool get showInlineLoader => isRefreshing.value && orders.isNotEmpty;
  int get activeFilterCount {
    var count = 0;
    if (searchQuery.value.trim().isNotEmpty) {
      count++;
    }
    if (selectedCustomerId.value != null) {
      count++;
    }
    if (startDate.value != null || endDate.value != null) {
      count++;
    }
    return count;
  }

  List<OrderModel> get visibleOrders {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return orders;
    }

    return orders
        .where((order) {
          final fields = [
            order.orderNo,
            order.customer?.name,
            order.customer?.phone,
            order.status,
            formatDate(order.orderDate),
          ];

          return fields.any(
            (value) => value != null && value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchOrders(reset: true);
    }
  }

  Future<void> onTabActivated() => fetchOrders(reset: true);

  Future<void> fetchOrders({required bool reset}) async {
    final requestedQuery = searchQuery.value.trim();
    final hasExistingItems = orders.isNotEmpty;

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
      final response = await _orderRepository.fetchOrders(
        page: pageToLoad,
        query: requestedQuery.isEmpty ? null : requestedQuery,
        status: activeStatusTab.value,
        customerId: selectedCustomerId.value,
        startDate: startDate.value,
        endDate: endDate.value,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final fetchedOrders = response.data ?? const <OrderModel>[];

      if (reset) {
        orders.assignAll(_deduplicateOrders(fetchedOrders));
      } else {
        orders.assignAll(_deduplicateOrders([...orders, ...fetchedOrders]));
      }
      _hasLoadedOnce = true;
      _lastIssuedQuery = requestedQuery;

      final currentPage = response.meta?.currentPage ?? pageToLoad;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      if (orders.isEmpty) {
        infoMessage.value = hasAnyQueryApplied
            ? 'No orders matched the current filters.'
            : 'No orders have been created yet.';
      } else if (visibleOrders.isEmpty && requestedQuery.isNotEmpty) {
        infoMessage.value = 'No loaded orders matched "$requestedQuery".';
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (reset && !hasExistingItems) {
        orders.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load orders right now.';
      if (reset && !hasExistingItems) {
        orders.clear();
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        isInitialLoading.value = false;
        isRefreshing.value = false;
        isLoadingMore.value = false;
        isSearching.value = false;

        if (_pendingReset) {
          _pendingReset = false;
          unawaited(fetchOrders(reset: true));
        }
      }
    }
  }

  Future<void> retry() => fetchOrders(reset: true);

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
        unawaited(fetchOrders(reset: true));
      } else {
        infoMessage.value = orders.isEmpty ? infoMessage.value : null;
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

      unawaited(fetchOrders(reset: true));
    });
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty) {
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
      unawaited(fetchOrders(reset: true));
    }
  }

  Future<void> applyFilters({
    int? customerId,
    DateTimeRange? dateRange,
  }) async {
    selectedCustomerId.value = customerId;
    startDate.value = dateRange == null
        ? null
        : _formatApiDate(dateRange.start);
    endDate.value = dateRange == null ? null : _formatApiDate(dateRange.end);
    await fetchOrders(reset: true);
  }

  Future<void> clearFilters() async {
    final hadFilters = hasActiveFilters;
    selectedCustomerId.value = null;
    startDate.value = null;
    endDate.value = null;

    if (hadFilters) {
      await fetchOrders(reset: true);
    }
  }

  Future<void> clearAllCriteria() async {
    final hadSearch =
        searchQuery.value.isNotEmpty || _lastIssuedQuery.isNotEmpty;
    final hadFilters = hasActiveFilters;

    _searchDebounce?.cancel();
    searchQuery.value = '';
    isSearching.value = false;
    _lastIssuedQuery = '';
    selectedCustomerId.value = null;
    startDate.value = null;
    endDate.value = null;

    if (hadSearch || hadFilters) {
      await fetchOrders(reset: true);
    }
  }

  DateTimeRange? get selectedDateRange {
    final start = _tryParseDate(startDate.value);
    final end = _tryParseDate(endDate.value);
    if (start == null || end == null) {
      return null;
    }

    return DateTimeRange(start: start, end: end);
  }

  Future<void> loadMoreIfNeeded(ScrollMetrics metrics) async {
    if (isInitialLoading.value || isRefreshing.value || isLoadingMore.value) {
      return;
    }
    if (!_hasNextPage) {
      return;
    }

    final remainingScroll = metrics.maxScrollExtent - metrics.pixels;
    if (remainingScroll <= 240) {
      await fetchOrders(reset: false);
    }
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  String formatDate(String? value) {
    final date = _tryParseDate(value);
    if (date == null) {
      return '-';
    }

    const months = [
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

    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> changeStatusTab(String status) async {
    if (activeStatusTab.value == status) {
      return;
    }

    activeStatusTab.value = status;
    await fetchOrders(reset: true);
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    unawaited(loadMoreIfNeeded(scrollController.position));
  }

  List<OrderModel> _deduplicateOrders(List<OrderModel> items) {
    final uniqueById = <int, OrderModel>{};
    final withoutId = <OrderModel>[];

    for (final order in items) {
      final id = order.id;
      if (id == null) {
        if (!withoutId.any(
          (item) =>
              item.orderNo == order.orderNo &&
              item.customer?.name == order.customer?.name &&
              item.grandTotal == order.grandTotal,
        )) {
          withoutId.add(order);
        }
        continue;
      }

      uniqueById[id] = order;
    }

    return [...uniqueById.values, ...withoutId];
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.split('T').first);
  }

  String _formatApiDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchTextController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
