import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../models/barcode_resolve_response.dart';
import '../models/create_or_update_barcode_product_request.dart';
import '../models/purchase_barcode_lookup_response.dart';

class InventoryManagerRepository {
  InventoryManagerRepository({
    required ProductRepository productRepository,
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _productRepository = productRepository,
       _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ProductRepository _productRepository;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<ProductModel?> findProductByBarcode(String barcode) async {
    final response = await resolveProductBarcode(barcode);
    return response.data;
  }

  Future<BarcodeResolveResponse> resolveProductBarcode(String barcode) async {
    final token = await _requireToken();
    final response = await _apiClient.get(
      ApiEndpoints.resolveBarcodeProduct(_normalizeBarcode(barcode)),
      token: token,
    );
    return BarcodeResolveResponse.fromJson(response);
  }

  Future<ProductModel> getProductByBarcode(String barcode) async {
    final token = await _requireToken();
    final response = await _apiClient.get(
      ApiEndpoints.barcodeProductDetails(_normalizeBarcode(barcode)),
      token: token,
    );

    if (response['data'] is Map<String, dynamic>) {
      return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException(message: 'Product details were not returned.');
  }

  Future<PurchaseBarcodeLookupResponse> getPurchaseProductByBarcode(
    String barcode,
  ) async {
    final token = await _requireToken();
    final response = await _apiClient.get(
      ApiEndpoints.purchaseProductByBarcode(_normalizeBarcode(barcode)),
      token: token,
    );
    return PurchaseBarcodeLookupResponse.fromJson(response);
  }

  Future<ProductModel> createProductFromBarcode(
    CreateOrUpdateBarcodeProductRequest request,
  ) async {
    final token = await _requireToken();
    await _apiClient.post(
      ApiEndpoints.barcodeProducts(),
      token: token,
      body: request.toJson(),
    );
    return getProductByBarcode(request.barcode);
  }

  Future<ProductModel> updateProductByBarcode(
    String barcode,
    CreateOrUpdateBarcodeProductRequest request,
  ) async {
    final token = await _requireToken();
    await _apiClient.put(
      ApiEndpoints.updateBarcodeProduct(_normalizeBarcode(barcode)),
      token: token,
      body: request.toJson(),
    );
    return getProductByBarcode(request.barcode);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _productRepository.fetchCategories();
    return response.data ?? const <CategoryModel>[];
  }

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

  String _normalizeBarcode(String value) {
    return value.trim();
  }
}
