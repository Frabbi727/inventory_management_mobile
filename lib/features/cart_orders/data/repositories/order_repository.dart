import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/create_order_request_model.dart';
import '../models/create_order_response_model.dart';
import '../models/order_details_response_model.dart';
import '../models/order_list_response_model.dart';

class OrderRepository {
  OrderRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

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
    int? customerId,
    String? startDate,
    String? endDate,
  }) async {
    final token = await _requireToken();

    final queryParameters = <String, String>{'page': page.toString()};

    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (customerId != null) {
      queryParameters['customer_id'] = customerId.toString();
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParameters['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParameters['end_date'] = endDate;
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
    final token = await _requireToken();

    final response = await _apiClient.post(
      ApiEndpoints.orders,
      token: token,
      body: request.toJson(),
    );

    return CreateOrderResponseModel.fromJson(response);
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

    await _apiClient.delete(
      ApiEndpoints.orderDetails(orderId),
      token: token,
    );
  }
}
