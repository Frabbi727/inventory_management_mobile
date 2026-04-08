import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/create_order_request_model.dart';
import '../models/create_order_response_model.dart';

class OrderRepository {
  OrderRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CreateOrderResponseModel> createOrder(
    CreateOrderRequestModel request,
  ) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.orders,
      token: token,
      body: request.toJson(),
    );

    return CreateOrderResponseModel.fromJson(response);
  }
}
