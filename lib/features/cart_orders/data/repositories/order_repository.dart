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
import '../models/create_order_request_model.dart';
import '../models/create_order_response_model.dart';
import '../models/order_details_response_model.dart';
import '../models/order_list_response_model.dart';

class OrderRepository {
  OrderRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required PendingActionsRepository pendingActionsRepository,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _pendingActionsRepository = pendingActionsRepository;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final PendingActionsRepository _pendingActionsRepository;
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

    return OrderListResponseModel.fromJson(response);
  }

  Future<OrderDetailsResponseModel> fetchOrderDetails(int orderId) async {
    final token = await _requireToken();

    final response = await _apiClient.get(
      ApiEndpoints.orderDetails(orderId),
      token: token,
    );

    return OrderDetailsResponseModel.fromJson(response);
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
    final token = await _requireToken();

    final response = await _apiClient.put(
      ApiEndpoints.orderDetails(orderId),
      token: token,
      body: request.toJson(),
    );

    return CreateOrderResponseModel.fromJson(response);
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
    final token = await _requireToken();

    await _apiClient.delete(ApiEndpoints.orderDetails(orderId), token: token);
  }
}
