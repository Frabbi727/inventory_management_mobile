import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/product_list_response_model.dart';

class ProductRepository {
  ProductRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<ProductListResponseModel> fetchProducts({
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

    final queryParameters = <String, String>{
      'page': page.toString(),
      'status': 'active',
    };

    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }

    final response = await _apiClient.get(
      ApiEndpoints.products,
      token: token,
      queryParameters: queryParameters,
    );

    return ProductListResponseModel.fromJson(response);
  }
}
