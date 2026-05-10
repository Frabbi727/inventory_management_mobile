import 'dart:convert';
import 'package:b2b_inventory_management/core/offline/sync_manager.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/offline/models/pending_action_model.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../customers/data/repositories/customer_cache_repository.dart';
import 'package:b2b_inventory_management/core/models/pagination_links_model.dart';
import 'package:b2b_inventory_management/core/models/pagination_meta_model.dart';
import '../models/order_customer_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/order_list_response_model.dart';
import '../models/create_order_request_model.dart';
import '../models/create_order_response_model.dart';
import '../models/order_details_response_model.dart';
import 'order_cache_repository.dart';

class OrderRepository {
  OrderRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required PendingActionsRepository pendingActionsRepository,
    required CustomerCacheRepository customerCacheRepository,
    required OrderCacheRepository orderCacheRepository,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _pendingActionsRepository = pendingActionsRepository,
        _customerCacheRepository = customerCacheRepository,
        _orderCacheRepository = orderCacheRepository;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final PendingActionsRepository _pendingActionsRepository;
  final CustomerCacheRepository _customerCacheRepository;
  final OrderCacheRepository _orderCacheRepository;
  final Uuid _uuid = const Uuid();

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    return token;
  }

  Future<OrderListResponseModel> fetchOrders({
    int page = 1,
    String? query,
    String? status,
    String? startDate,
    String? endDate,
    String? intendedDeliveryStart,
    String? intendedDeliveryEnd,
    String? deliveryState,
    String? paymentStatus,
  }) async {
    List<OrderModel>? apiOrders;
    PaginationMetaModel? apiMeta;
    PaginationLinksModel? apiLinks;

    final isOnline = Get.isRegistered<SyncManager>() ? Get.find<SyncManager>().isOnline.value : true;

    if (isOnline) {
      try {
        final token = await _requireToken();

        final queryParameters = <String, String>{'page': page.toString()};

        if (query != null && query.isNotEmpty) {
          queryParameters['q'] = query;
        }
        if (status != null && status.isNotEmpty) {
          queryParameters['status'] = status;
        }
        if (startDate != null && startDate.isNotEmpty) {
          queryParameters['start_date'] = startDate;
        }
        if (endDate != null && endDate.isNotEmpty) {
          queryParameters['end_date'] = endDate;
        }
        if (intendedDeliveryStart != null && intendedDeliveryStart.isNotEmpty) {
          queryParameters['intended_delivery_start'] = intendedDeliveryStart;
        }
        if (intendedDeliveryEnd != null && intendedDeliveryEnd.isNotEmpty) {
          queryParameters['intended_delivery_end'] = intendedDeliveryEnd;
        }
        if (deliveryState != null && deliveryState.isNotEmpty) {
          queryParameters['delivery_state'] = deliveryState;
        }
        if (paymentStatus != null && paymentStatus.isNotEmpty) {
          queryParameters['payment_status'] = paymentStatus;
        }

        final response = await _apiClient.get(
          ApiEndpoints.orders,
          token: token,
          queryParameters: queryParameters,
        );

        final model = OrderListResponseModel.fromJson(response);
        apiOrders = model.data;
        apiMeta = model.meta;
        apiLinks = model.links;

        if (apiOrders != null && apiOrders.isNotEmpty) {
          await _orderCacheRepository.saveOrders(apiOrders);
        }
      } catch (e) {
        if (page > 1) rethrow;
      }
    }

    // Always fetch pending local orders on page 1
    List<OrderModel> localOrders = [];
    if (page == 1 && (status == null || status == 'draft' || status == 'all')) {
      localOrders = await _getPendingLocalOrders();
    }

    // Fetch cached orders if API call failed or returned empty (only on first page)
    List<OrderModel> cachedOrders = [];
    if (page == 1 && (apiOrders == null || apiOrders.isEmpty)) {
      cachedOrders = await _orderCacheRepository.getOrders(status: status);
    }

    // Mark cached orders as 'pending_sync' if they have a pending PUT action
    for (var i = 0; i < cachedOrders.length; i++) {
      final orderId = cachedOrders[i].id;
      if (orderId != null) {
        final hasUpdate = await _pendingActionsRepository.hasPendingUpdate(
          ApiEndpoints.orderDetails(orderId),
        );
        if (hasUpdate) {
          cachedOrders[i] = cachedOrders[i].copyWith(
            paymentStatus: 'pending_sync',
          );
        }
      }
    }

    // Merge results: Local Pending > API Results > Cached Results
    final allOrders = <OrderModel>[...localOrders, ...(apiOrders ?? []), ...cachedOrders];
    final uniqueOrders = _deduplicateOrders(allOrders);

    return OrderListResponseModel(
      data: uniqueOrders,
      meta: apiMeta,
      links: apiLinks,
    );
  }

  List<OrderModel> _deduplicateOrders(List<OrderModel> orders) {
    final Map<dynamic, OrderModel> uniqueMap = {};
    for (final order in orders) {
      // Use ID if available, otherwise orderNo (for pending items)
      final key = order.id ?? order.orderNo; 
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = order;
      }
    }
    return uniqueMap.values.toList();
  }

  Future<List<OrderModel>> _getPendingLocalOrders() async {
    try {
      final pendingActions = await _pendingActionsRepository.getPendingActions();
      final localOrders = <OrderModel>[];

      for (final action in pendingActions) {
        if (action.method == 'POST' && action.endpoint == ApiEndpoints.orders) {
          try {
            final payload = jsonDecode(action.payload);
            final request = CreateOrderRequestModel.fromJson(payload);
            
            OrderCustomerModel? customer;
            if (request.customerId != null) {
              final cachedCustomer = await _customerCacheRepository.getCustomerById(request.customerId!);
              if (cachedCustomer != null) {
                customer = OrderCustomerModel(
                  id: cachedCustomer.id,
                  name: cachedCustomer.name,
                  phone: cachedCustomer.phone,
                );
              }
            }

            localOrders.add(OrderModel(
              id: null, // Indicates it's local
              orderNo: 'PENDING-${action.mobileRef.substring(0, 5).toUpperCase()}',
              orderDate: request.orderDate,
              intendedDeliveryAt: request.intendedDeliveryAt,
              grandTotal: request.paymentAmount,
              paymentAmount: request.paymentAmount,
              paymentStatus: 'pending_sync',
              status: 'draft',
              customer: customer,
              note: request.note,
            ));
          } catch (_) {}
        }
      }

      return localOrders;
    } catch (_) {
      return [];
    }
  }

  Future<OrderDetailsResponseModel> fetchOrderDetails(int orderId) async {
    final isOnline = Get.isRegistered<SyncManager>() ? Get.find<SyncManager>().isOnline.value : true;

    if (isOnline) {
      final token = await _requireToken();

      final response = await _apiClient.get(
        ApiEndpoints.orderDetails(orderId),
        token: token,
      );

      final model = OrderDetailsResponseModel.fromJson(response);
      if (model.data != null) {
        await _orderCacheRepository.saveOrder(model.data!);
      }
      return model;
    } else {
      final cachedOrder = await _orderCacheRepository.getOrderById(orderId);
      if (cachedOrder != null) {
        return OrderDetailsResponseModel(data: cachedOrder);
      }
      throw ApiException(message: 'Order details not found offline.');
    }
  }

  Future<CreateOrderResponseModel> createOrder(
    CreateOrderRequestModel request,
  ) async {
    // 1. Generate a random UUID string and assign it to a variable mobile_ref.
    final mobileRef = _uuid.v4();

    // 2. Construct the exact JSON map that the Laravel backend expects for an order.
    // Crucial: Include the mobile_ref inside this payload map.
    final requestWithRef = CreateOrderRequestModel(
      customerId: request.customerId,
      orderDate: request.orderDate,
      intendedDeliveryAt: request.intendedDeliveryAt,
      note: request.note,
      discountType: request.discountType,
      discountValue: request.discountValue,
      paymentAmount: request.paymentAmount,
      items: request.items,
      mobileRef: mobileRef,
    );

    // 4. jsonEncode() this map.
    final payload = jsonEncode(requestWithRef.toJson());

    // 5. Insert a new row into the pending_actions SQLite table
    final action = PendingAction(
      endpoint: ApiEndpoints.orders,
      method: 'POST',
      payload: payload,
      mobileRef: mobileRef,
      status: 'pending',
    );

    await _pendingActionsRepository.insertAction(action);

    // Update pending count in SyncManager if registered
    if (Get.isRegistered<SyncManager>()) {
      Get.find<SyncManager>().updatePendingCount();
    }

    // 6. Navigate the user away and show a "Saved Offline!" success message.
    // (Navigation is usually handled in the Controller, but we return the success message here)
    return const CreateOrderResponseModel(
      message: 'Saved Offline!',
    );
  }

  Future<CreateOrderResponseModel> updateOrderDraft(
    int orderId,
    CreateOrderRequestModel request,
  ) async {
    final isOnline = Get.isRegistered<SyncManager>() ? Get.find<SyncManager>().isOnline.value : true;

    if (isOnline) {
      final token = await _requireToken();

      final response = await _apiClient.put(
        ApiEndpoints.orderDetails(orderId),
        token: token,
        body: request.toJson(),
      );

      final model = CreateOrderResponseModel.fromJson(response);
      if (model.data != null) {
        await _orderCacheRepository.saveOrder(model.data!);
      }
      return model;
    } else {
      // OFFLINE UPDATE: 
      // 1. Fetch current cached order to merge changes
      final existingOrder = await _orderCacheRepository.getOrderById(orderId);
      if (existingOrder == null) {
        throw ApiException(message: 'Cannot edit an order that is not cached locally while offline.');
      }

      // 2. Create updated order model (rough merge for local preview)
      final updatedOrder = existingOrder.copyWith(
        orderDate: request.orderDate,
        intendedDeliveryAt: request.intendedDeliveryAt,
        grandTotal: request.paymentAmount,
        paymentAmount: request.paymentAmount,
        note: request.note,
        items: request.items?.map((i) => OrderItemModel(
          productId: i.productId,
          productVariantId: i.productVariantId,
          quantity: i.quantity,
        )).toList(),
      );

      // 3. Save to local cache so UI reflects changes immediately
      await _orderCacheRepository.saveOrder(updatedOrder);

      // 4. Queue the update action
      final payload = jsonEncode(request.toJson());
      final action = PendingAction(
        endpoint: ApiEndpoints.orderDetails(orderId),
        method: 'PUT',
        payload: payload,
        mobileRef: 'UPDATE-$orderId-${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
      );

      await _pendingActionsRepository.insertAction(action);
      
      if (Get.isRegistered<SyncManager>()) {
        Get.find<SyncManager>().updatePendingCount();
      }

      return CreateOrderResponseModel(
        message: 'Draft updated offline.',
        data: updatedOrder,
      );
    }
  }

  Future<CreateOrderResponseModel> confirmOrder(int orderId) async {
    final token = await _requireToken();

    final response = await _apiClient.post(
      ApiEndpoints.orderConfirm(orderId),
      token: token,
    );

    return CreateOrderResponseModel.fromJson(response);
  }

  Future<void> deleteOrder(int orderId) async {
    final isOnline = Get.isRegistered<SyncManager>() ? Get.find<SyncManager>().isOnline.value : true;

    if (isOnline) {
      final token = await _requireToken();
      await _apiClient.delete(ApiEndpoints.orderDetails(orderId), token: token);
      await _orderCacheRepository.deleteOrder(orderId);
    } else {
      // OFFLINE DELETE:
      // 1. Remove from local cache
      await _orderCacheRepository.deleteOrder(orderId);

      // 2. Queue the delete action
      final action = PendingAction(
        endpoint: ApiEndpoints.orderDetails(orderId),
        method: 'DELETE',
        payload: '{}',
        mobileRef: 'DELETE-$orderId-${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
      );

      await _pendingActionsRepository.insertAction(action);
      
      if (Get.isRegistered<SyncManager>()) {
        Get.find<SyncManager>().updatePendingCount();
      }
    }
  }

  Future<void> saveToCache(OrderModel order) async {
    await _orderCacheRepository.saveOrder(order);
  }
}
