import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/offline/models/pending_action_model.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/allocation_model.dart';

class AllocationRepository {
  AllocationRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required PendingActionsRepository pendingActionsRepository,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _pendingActionsRepository = pendingActionsRepository;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final PendingActionsRepository _pendingActionsRepository;

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
    final body = <String, dynamic>{
      'items': items,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    final isOnline = Get.isRegistered<SyncManager>()
        ? Get.find<SyncManager>().isOnline.value
        : true;

    if (!isOnline) {
      final action = PendingAction(
        endpoint: ApiEndpoints.myAllocationReturns(allocationId),
        method: 'POST',
        payload: jsonEncode(body),
        mobileRef:
            'RETURN-$allocationId-${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
      );
      await _pendingActionsRepository.insertAction(action);
      if (Get.isRegistered<SyncManager>()) {
        Get.find<SyncManager>().updatePendingCount();
      }
      return;
    }

    final token = await _requireToken();
    await _apiClient.post(
      ApiEndpoints.myAllocationReturns(allocationId),
      token: token,
      body: body,
    );
  }
}
