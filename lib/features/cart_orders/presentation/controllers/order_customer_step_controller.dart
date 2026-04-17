import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import 'cart_controller.dart';

class OrderCustomerStepController extends GetxController {
  OrderCustomerStepController({
    required CartController cartController,
    required CustomerSearchController customerSearchController,
  }) : _cartController = cartController,
       _customerSearchController = customerSearchController;

  final CartController _cartController;
  final CustomerSearchController _customerSearchController;

  late final TextEditingController searchController;
  late final ScrollController scrollController;

  CartController get cartController => _cartController;
  CustomerSearchController get customerSearchController =>
      _customerSearchController;

  List<CustomerModel> get customers => _customerSearchController.customers;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController(
      text: _customerSearchController.searchQuery.value,
    );
    scrollController = ScrollController()..addListener(_handleScroll);
    _customerSearchController.ensureLoaded();
  }

  Future<void> ensureLoaded() => _customerSearchController.ensureLoaded();

  void onSearchChanged(String value) {
    _customerSearchController.onSearchChanged(value);
  }

  void clearSearch() {
    searchController.clear();
    _customerSearchController.clearSearch();
  }

  Future<void> openAddCustomer() async {
    final result = await Get.toNamed(AppRoutes.addCustomer);
    if (result is CustomerModel) {
      selectCustomer(result);
      clearSearch();
      await _customerSearchController.retry();
    }
  }

  void selectCustomer(CustomerModel? customer) {
    _cartController.setSelectedCustomer(customer);
  }

  void syncSearchField() {
    final value = _customerSearchController.searchQuery.value;
    if (searchController.text == value) {
      return;
    }

    searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    _customerSearchController.loadMoreIfNeeded(scrollController.position);
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    searchController.dispose();
    super.onClose();
  }
}
