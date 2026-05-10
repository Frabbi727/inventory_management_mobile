import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../network/api_client.dart';
import '../notifications/notification_service.dart';
import '../storage/token_storage.dart';
import '../offline/models/pending_action_model.dart';
import '../offline/repositories/pending_actions_repository.dart';
import '../../features/cart_orders/data/models/order_model.dart';
import '../../features/cart_orders/data/repositories/order_repository.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/products/data/repositories/product_cache_repository.dart';
import '../../features/customers/data/repositories/customer_repository.dart';
import '../../features/customers/data/repositories/customer_cache_repository.dart';

class SyncManager extends GetxService {
  final PendingActionsRepository _pendingActionsRepository = Get.find();
  final ProductRepository _productRepository = Get.find();
  final ProductCacheRepository _productCacheRepository = Get.find();
  final CustomerRepository _customerRepository = Get.find();
  final CustomerCacheRepository _customerCacheRepository = Get.find();
  final OrderRepository _orderRepository = Get.find();
  final ApiClient _apiClient = Get.find();
  final TokenStorage _tokenStorage = Get.find();
  final NotificationService _notificationService = Get.find();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final isSyncing = false.obs;
  final pendingActionsCount = 0.obs;
  final isOnline = true.obs;

  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    // Initial check
    _connectivity.checkConnectivity().then(_handleConnectivityChange);
    updatePendingCount();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> updatePendingCount() async {
    pendingActionsCount.value = await _pendingActionsRepository.getPendingActionsCount();
  }

  Future<void> triggerManualSync() async {
    if (isSyncing.value) return;
    
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      Get.snackbar(
        'Offline',
        'Cannot sync while offline. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await refreshCache();
    await processQueue();
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi)) {
      isOnline.value = true;
      refreshCache();
      processQueue();
    } else {
      isOnline.value = false;
    }
  }

  Future<void> refreshCache() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      // 1. Fetch all products and customers
      final productResponse = await _productRepository.fetchProducts(page: 1);
      final customerResponse = await _customerRepository.fetchCustomers(page: 1);
      
      // 2. Fetch recent orders (especially drafts)
      await _orderRepository.fetchOrders(page: 1, status: 'draft');
      await _orderRepository.fetchOrders(page: 1); // also fetch all for context

      if (productResponse.data != null) {
        // 2. Clear and 3. Insert fresh data
        await _productCacheRepository.clearProducts();
        await _productCacheRepository.saveProducts(productResponse.data!);
      }

      if (customerResponse.data != null) {
        await _customerCacheRepository.clearCustomers();
        await _customerCacheRepository.saveCustomers(customerResponse.data!);
      }
    } catch (_) {
      // Fail silently or log
    }
  }

  Future<void> processQueue() async {
    if (isSyncing.value) return;
    isSyncing.value = true;

    try {
      final pendingActions = await _pendingActionsRepository.getPendingActions();
      pendingActionsCount.value = pendingActions.length;
      
      if (pendingActions.isEmpty) {
        return;
      }

      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      for (final action in pendingActions) {
        final success = await _processAction(action, token);
        if (success) {
          await _pendingActionsRepository.deleteAction(action.id!);
          await updatePendingCount();
        } else {
          // If connection drops or 5xx, stop and retry later
          break;
        }
      }

      // Check if queue is now empty to show notification
      final remainingCount = await _pendingActionsRepository.getPendingActionsCount();
      pendingActionsCount.value = remainingCount;
      
      if (remainingCount == 0 && pendingActions.isNotEmpty) {
        _notificationService.showSyncCompleteNotification(pendingActions.length);
      }
    } catch (_) {
      // Fail silently
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> _processAction(PendingAction action, String token) async {
    try {
      final payload = jsonDecode(action.payload);
      dynamic response;

      switch (action.method.toUpperCase()) {
        case 'POST':
          response = await _apiClient.post(action.endpoint, body: payload, token: token);
          break;
        case 'PUT':
          response = await _apiClient.put(action.endpoint, body: payload, token: token);
          break;
        case 'DELETE':
          response = await _apiClient.delete(action.endpoint, token: token);
          break;
        default:
          return false;
      }

      // Update local cache if the response contains order data
      if (response != null && response['data'] != null) {
        if (action.endpoint.contains('/orders')) {
          try {
            final order = OrderModel.fromJson(response['data']);
            await _orderRepository.saveToCache(order);
          } catch (_) {}
        }
      }

      return true;
    } catch (e) {
      // Failed to process action
      return false; 
    }
  }
}
