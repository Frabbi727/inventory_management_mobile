import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/notification_list_response_model.dart';
import '../models/unread_count_response_model.dart';

class NotificationRepository {
  NotificationRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
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

  Future<NotificationListResponseModel> fetchNotifications({
    int page = 1,
    String? status,
  }) async {
    final token = await _requireToken();
    final queryParameters = <String, String>{'page': page.toString()};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      token: token,
      queryParameters: queryParameters,
    );

    return NotificationListResponseModel.fromJson(response);
  }

  Future<UnreadCountResponseModel> fetchUnreadCount() async {
    final token = await _requireToken();
    final response = await _apiClient.get(
      ApiEndpoints.notificationsUnreadCount,
      token: token,
    );

    return UnreadCountResponseModel.fromJson(response);
  }

  Future<void> markAsRead(int notificationId) async {
    final token = await _requireToken();
    await _apiClient.post(ApiEndpoints.notificationRead(notificationId), token: token);
  }

  Future<void> markAsUnread(int notificationId) async {
    final token = await _requireToken();
    await _apiClient.post(
      ApiEndpoints.notificationUnread(notificationId),
      token: token,
    );
  }

  Future<void> markAllAsRead() async {
    final token = await _requireToken();
    await _apiClient.post(ApiEndpoints.notificationsReadAll, token: token);
  }
}
