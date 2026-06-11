import 'dart:convert';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/offline/models/pending_action_model.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/create_customer_request_model.dart';
import '../models/create_customer_response_model.dart';
import '../models/customer_list_response_model.dart';
import '../models/customer_model.dart';
import 'customer_cache_repository.dart';

class CustomerRepository {
  CustomerRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    CustomerCacheRepository? customerCacheRepository,
    PendingActionsRepository? pendingActionsRepository,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       _customerCacheRepository = customerCacheRepository,
       _pendingActionsRepository = pendingActionsRepository;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final CustomerCacheRepository? _customerCacheRepository;
  final PendingActionsRepository? _pendingActionsRepository;
  final Uuid _uuid = const Uuid();

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
    final isOnline = Get.isRegistered<SyncManager>()
        ? Get.find<SyncManager>().isOnline.value
        : true;

    if (!isOnline) {
      return _createCustomerOffline(request);
    }

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

  Future<CreateCustomerResponseModel> _createCustomerOffline(
    CreateCustomerRequestModel request,
  ) async {
    final mobileRef = _uuid.v4();
    final tempId = -(DateTime.now().millisecondsSinceEpoch % 1000000000);

    final requestWithRef = CreateCustomerRequestModel(
      name: request.name,
      phone: request.phone,
      address: request.address,
      area: request.area,
      mobileRef: mobileRef,
    );

    final action = PendingAction(
      endpoint: ApiEndpoints.customers,
      method: 'POST',
      payload: jsonEncode(requestWithRef.toJson()),
      mobileRef: mobileRef,
      status: 'pending',
    );

    await _pendingActionsRepository?.insertAction(action);

    if (Get.isRegistered<SyncManager>()) {
      Get.find<SyncManager>().updatePendingCount();
    }

    final tempCustomer = CustomerModel(
      id: tempId,
      name: request.name,
      phone: request.phone,
      address: request.address,
      area: request.area,
      localMobileRef: mobileRef,
    );

    await _customerCacheRepository?.saveCustomer(tempCustomer);

    return CreateCustomerResponseModel(
      message: 'Customer saved offline.',
      data: tempCustomer,
    );
  }
}
