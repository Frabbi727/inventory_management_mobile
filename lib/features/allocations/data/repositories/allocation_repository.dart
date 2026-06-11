import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/allocation_model.dart';

class AllocationRepository {
  AllocationRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
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

  Future<List<AllocationModel>> fetchMyAllocations({String? status}) async {
    final token = await _requireToken();
    final queryParameters = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.myAllocations,
      token: token,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AllocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AllocationModel> fetchAllocationDetails(int id) async {
    final token = await _requireToken();
    final response = await _apiClient.get(
      ApiEndpoints.myAllocationDetails(id),
      token: token,
    );
    return AllocationModel.fromJson(response);
  }

  Future<void> submitReturns({
    required int allocationId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final token = await _requireToken();
    await _apiClient.post(
      ApiEndpoints.myAllocationReturns(allocationId),
      token: token,
      body: {
        'items': items,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }
}
