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
  final Map<String, ProductListResponseModel> _responseCache = {};
  final Map<String, Future<ProductListResponseModel>> _inflightRequests = {};

  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    String? query,
    bool forceRefresh = false,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final cacheKey = '$page|${query?.trim() ?? ''}';
    if (!forceRefresh) {
      final cachedResponse = _responseCache[cacheKey];
      if (cachedResponse != null) {
        return cachedResponse;
      }

      final inflightRequest = _inflightRequests[cacheKey];
      if (inflightRequest != null) {
        return inflightRequest;
      }
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'status': 'active',
    };

    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }

    final request = _apiClient
        .get(
          ApiEndpoints.products,
          token: token,
          queryParameters: queryParameters,
        )
        .then((response) => ProductListResponseModel.fromJson(response));

    _inflightRequests[cacheKey] = request;

    try {
      final parsedResponse = await request;
      _responseCache[cacheKey] = parsedResponse;
      return parsedResponse;
    } finally {
      _inflightRequests.remove(cacheKey);
    }
  }
}
