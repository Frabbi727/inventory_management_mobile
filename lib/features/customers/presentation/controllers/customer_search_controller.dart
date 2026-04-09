import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerSearchController extends GetxController {
  CustomerSearchController({required CustomerRepository customerRepository})
    : _customerRepository = customerRepository;

  final CustomerRepository _customerRepository;

  final customers = <CustomerModel>[].obs;
  final selectedCustomer = Rxn<CustomerModel>();
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
  String _lastExecutedQuery = '';
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  bool get hasActiveSearch => searchQuery.value.isNotEmpty;
  bool get hasErrorState =>
      errorMessage.value != null &&
      customers.isEmpty &&
      !isInitialLoading.value;
  bool get hasEmptyState =>
      customers.isEmpty &&
      errorMessage.value == null &&
      !isInitialLoading.value &&
      !isSearching.value;

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchCustomers(reset: true);
    }
  }

  Future<void> fetchCustomers({required bool reset}) async {
    final requestedQuery = searchQuery.value.trim();
    final hasExistingItems = customers.isNotEmpty;

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
      final response = await _customerRepository.fetchCustomers(
        page: pageToLoad,
        query: requestedQuery.isEmpty ? null : requestedQuery,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final fetchedCustomers = response.data ?? const <CustomerModel>[];
      if (reset) {
        customers.assignAll(_deduplicateCustomers(fetchedCustomers));
      } else {
        customers.assignAll(
          _deduplicateCustomers([...customers, ...fetchedCustomers]),
        );
      }
      _hasLoadedOnce = true;

      final currentPage = response.meta?.currentPage ?? pageToLoad;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      infoMessage.value = customers.isEmpty
          ? (requestedQuery.isEmpty
                ? 'No customers are available right now.'
                : 'No customers found for "$requestedQuery".')
          : null;
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (reset) {
        customers.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load customers right now.';
      if (reset) {
        customers.clear();
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
      final hadSearch =
          searchQuery.value.isNotEmpty || _lastExecutedQuery.isNotEmpty;
      searchQuery.value = '';
      infoMessage.value = null;
      isSearching.value = false;
      _lastExecutedQuery = '';
      if (hadSearch || customers.isEmpty) {
        unawaited(fetchCustomers(reset: true));
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
        unawaited(fetchCustomers(reset: true));
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
      unawaited(fetchCustomers(reset: true));
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
    unawaited(fetchCustomers(reset: true));
  }

  void selectCustomer(CustomerModel customer) {
    selectedCustomer.value = customer;
    Get.back(result: customer);
  }

  Future<void> openAddCustomer() async {
    final result = await Get.toNamed(AppRoutes.addCustomer);
    if (result is CustomerModel) {
      selectCustomer(result);
    }
  }

  Future<void> retry() async {
    await ensureLoaded(forceRefresh: true);
  }

  Future<void> loadMoreIfNeeded(ScrollMetrics metrics) async {
    if (isInitialLoading.value || isLoadingMore.value || !_hasNextPage) {
      return;
    }

    final remainingScroll = metrics.maxScrollExtent - metrics.pixels;
    if (remainingScroll <= 240) {
      await fetchCustomers(reset: false);
    }
  }

  List<CustomerModel> _deduplicateCustomers(List<CustomerModel> items) {
    final uniqueById = <int?, CustomerModel>{};
    final withoutId = <CustomerModel>[];

    for (final customer in items) {
      if (customer.id == null) {
        if (!withoutId.any(
          (item) =>
              item.name == customer.name &&
              item.phone == customer.phone &&
              item.address == customer.address,
        )) {
          withoutId.add(customer);
        }
        continue;
      }

      uniqueById[customer.id] = customer;
    }

    return [...uniqueById.values, ...withoutId];
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
