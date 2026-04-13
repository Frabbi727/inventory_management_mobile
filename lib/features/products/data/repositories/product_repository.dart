import 'package:inventory_management_sales/features/products/data/models/category_response_model.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/product_details_response_model.dart';
import '../models/product_list_response_model.dart';
import '../models/subcategory_list_response_model.dart';
import '../models/product_subcategory_model.dart';

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
  final Map<int, ProductDetailsResponseModel> _detailsCache = {};
  final Map<int, Future<ProductDetailsResponseModel>> _inflightDetailRequests =
      {};

  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    String? query,
    int? categoryId,
    int? subcategoryId,
    bool forceRefresh = false,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final cacheKey =
        '$page|${query?.trim() ?? ''}|${categoryId ?? ''}|${subcategoryId ?? ''}';
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

    if (categoryId != null) {
      queryParameters['category_id'] = categoryId.toString();
    }
    if (subcategoryId != null) {
      queryParameters['subcategory_id'] = subcategoryId.toString();
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

  Future<ProductDetailsResponseModel> fetchProductDetails(
    int id, {
    bool forceRefresh = false,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    if (!forceRefresh) {
      final cachedResponse = _detailsCache[id];
      if (cachedResponse != null) {
        return cachedResponse;
      }

      final inflightRequest = _inflightDetailRequests[id];
      if (inflightRequest != null) {
        return inflightRequest;
      }
    }

    final request = _apiClient
        .get(ApiEndpoints.productDetails(id), token: token)
        .then((response) {
          final parsed = ProductDetailsResponseModel.fromJson(response);
          if (parsed.data == null) {
            throw ApiException(message: 'Product details were not returned.');
          }

          return parsed;
        });

    _inflightDetailRequests[id] = request;

    try {
      final parsedResponse = await request;
      _detailsCache[id] = parsedResponse;
      return parsedResponse;
    } finally {
      _inflightDetailRequests.remove(id);
    }
  }

  Future<CategoryResponseModel> fetchCategories() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.categories,
      token: token,
    );

    return CategoryResponseModel.fromJson(response);
  }

  Future<List<ProductSubcategoryModel>> fetchSubcategories({
    int? categoryId,
  }) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Authentication token not found.',
        statusCode: 401,
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.subcategories,
      token: token,
      queryParameters: categoryId == null
          ? null
          : <String, String>{'category_id': categoryId.toString()},
    );

    final parsed = SubcategoryListResponseModel.fromJson(response);
    return parsed.data ?? const <ProductSubcategoryModel>[];
  }
}
