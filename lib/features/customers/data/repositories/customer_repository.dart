import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/create_customer_request_model.dart';
import '../models/create_customer_response_model.dart';
import '../models/customer_list_response_model.dart';

class CustomerRepository {
  CustomerRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CustomerListResponseModel> fetchCustomers({
    int page = 1,
    String? query,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final queryParameters = <String, String>{'page': page.toString()};

    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }

    final response = await _apiClient.get(
      ApiEndpoints.customers,
      token: token,
      queryParameters: queryParameters,
    );

    return CustomerListResponseModel.fromJson(response);
  }

  Future<CreateCustomerResponseModel> createCustomer(
    CreateCustomerRequestModel request,
  ) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.customers,
      token: token,
      body: request.toJson(),
    );

    return CreateCustomerResponseModel.fromJson(response);
  }
}
