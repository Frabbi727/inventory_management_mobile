import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../models/barcode_resolve_response.dart';
import '../models/create_or_update_barcode_product_request.dart';
import '../models/create_or_update_purchase_request.dart';
import '../models/product_photo_upload_file.dart';
import '../models/purchase_response_model.dart';
import '../models/purchase_response_wrapper_model.dart';
import '../models/product_unit_list_response_model.dart';
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
    CreateOrUpdateBarcodeProductRequest request, {
    List<ProductPhotoUploadFile> photos = const <ProductPhotoUploadFile>[],
  }) async {
    final token = await _requireToken();
    if (photos.isEmpty) {
      await _apiClient.post(
        ApiEndpoints.barcodeProducts(),
        token: token,
        body: request.toJson(),
      );
    } else {
      await _apiClient.postMultipart(
        ApiEndpoints.barcodeProducts(),
        token: token,
        fields: request.toMultipartFields(),
        files: photos
            .map(
              (photo) => MultipartFileData(
                fieldName: 'photos[]',
                fileName: photo.fileName,
                bytes: photo.bytes,
              ),
            )
            .toList(),
      );
    }
    return getProductByBarcode(request.barcode);
  }

  Future<ProductModel> updateProductByBarcode(
    String barcode,
    CreateOrUpdateBarcodeProductRequest request, {
    List<ProductPhotoUploadFile> photos = const <ProductPhotoUploadFile>[],
  }) async {
    final token = await _requireToken();
    if (photos.isEmpty) {
      await _apiClient.put(
        ApiEndpoints.updateBarcodeProduct(_normalizeBarcode(barcode)),
        token: token,
        body: request.toJson(),
      );
    } else {
      await _apiClient.putMultipart(
        ApiEndpoints.updateBarcodeProduct(_normalizeBarcode(barcode)),
        token: token,
        fields: request.toMultipartFields(),
        files: photos
            .map(
              (photo) => MultipartFileData(
                fieldName: 'photos[]',
                fileName: photo.fileName,
                bytes: photo.bytes,
              ),
            )
            .toList(),
      );
    }
    return getProductByBarcode(request.barcode);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _productRepository.fetchCategories();
    return response.data ?? const <CategoryModel>[];
  }

  Future<List<ProductUnitModel>> fetchUnits() async {
    final token = await _requireToken();
    final response = await _apiClient.get(ApiEndpoints.units, token: token);
    final parsed = ProductUnitListResponseModel.fromJson(response);
    return parsed.data ?? const <ProductUnitModel>[];
  }

  Future<PurchaseResponseModel> createPurchase(
    CreateOrUpdatePurchaseRequest request,
  ) async {
    final token = await _requireToken();
    final response = await _apiClient.post(
      ApiEndpoints.purchases,
      token: token,
      body: request.toJson(),
    );
    final parsed = PurchaseResponseWrapperModel.fromJson(response);
    if (parsed.data == null) {
      throw ApiException(message: 'Purchase response was not returned.');
    }
    return parsed.data!;
  }

  Future<PurchaseResponseModel> updatePurchase(
    int purchaseId,
    CreateOrUpdatePurchaseRequest request,
  ) async {
    final token = await _requireToken();
    final response = await _apiClient.put(
      ApiEndpoints.purchaseDetails(purchaseId),
      token: token,
      body: request.toJson(),
    );
    final parsed = PurchaseResponseWrapperModel.fromJson(response);
    if (parsed.data == null) {
      throw ApiException(message: 'Purchase response was not returned.');
    }
    return parsed.data!;
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
