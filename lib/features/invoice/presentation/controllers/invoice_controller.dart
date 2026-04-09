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
  final orders = <OrderModel>[].obs;
  final isInitialLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();

  int _currentPage = 1;
  bool _hasNextPage = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetchOrders(reset: true);
  }

  Future<void> fetchOrders({required bool reset}) async {
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
      final response = await _orderRepository.fetchOrders(page: _currentPage);
      final fetchedOrders = response.data ?? const <OrderModel>[];

      if (reset) {
        orders.assignAll(fetchedOrders);
      } else {
        orders.addAll(fetchedOrders);
      }

      final currentPage = response.meta?.currentPage ?? _currentPage;
      final lastPage = response.meta?.lastPage ?? currentPage;
      _hasNextPage = (response.links?.next != null) || (currentPage < lastPage);
      _currentPage = currentPage + 1;

      infoMessage.value = orders.isEmpty
          ? 'No orders have been created yet.'
          : null;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      if (reset) {
        orders.clear();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load orders right now.';
      if (reset) {
        orders.clear();
      }
    } finally {
      isInitialLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> retry() => fetchOrders(reset: true);

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
    if (value == null || value.isEmpty) {
      return '-';
    }

    final normalized = value.split('T').first;
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }

    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final threshold = scrollController.position.maxScrollExtent - 200;
    if (scrollController.position.pixels >= threshold) {
      fetchOrders(reset: false);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
