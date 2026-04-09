import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerSearchController extends GetxController {
  CustomerSearchController({required CustomerRepository customerRepository})
    : _customerRepository = customerRepository;

  final CustomerRepository _customerRepository;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final customers = <CustomerModel>[].obs;
  final selectedCustomer = Rxn<CustomerModel>();
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
    fetchCustomers(reset: true);
  }

  Future<void> fetchCustomers({required bool reset}) async {
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
      final response = await _customerRepository.fetchCustomers(
        page: _currentPage,
        query: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      final fetchedCustomers = response.data ?? const <CustomerModel>[];
      if (reset) {
        customers.assignAll(fetchedCustomers);
      } else {
        customers.addAll(fetchedCustomers);
      }

      final currentPage = response.meta?.currentPage ?? _currentPage;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      infoMessage.value = customers.isEmpty
          ? 'No customers found for "${searchQuery.value}".'
          : null;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (reset) {
        customers.clear();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load customers right now.';
      if (reset) {
        customers.clear();
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
      if (hadSearch || customers.isEmpty) {
        fetchCustomers(reset: true);
      }
      return;
    }

    if (trimmed.length < 3) {
      infoMessage.value = 'Type 3 or more characters to narrow the list.';
      if (searchQuery.value.isNotEmpty) {
        searchQuery.value = '';
        fetchCustomers(reset: true);
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      searchQuery.value = trimmed;
      infoMessage.value = null;
      fetchCustomers(reset: true);
    });
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
    await fetchCustomers(reset: true);
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final threshold = scrollController.position.maxScrollExtent - 200;
    if (scrollController.position.pixels >= threshold) {
      fetchCustomers(reset: false);
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
