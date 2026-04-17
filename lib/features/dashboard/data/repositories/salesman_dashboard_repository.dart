import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/dashboard_range.dart';
import '../models/salesman_dashboard_response_model.dart';

class SalesmanDashboardRepository {
  SalesmanDashboardRepository({
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

  Future<SalesmanDashboardResponseModel> fetchDashboard({
    required DashboardRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _requireToken();
    final queryParameters = <String, String>{'range': range.apiValue};

    if (range == DashboardRange.custom) {
      if (startDate != null) {
        queryParameters['start_date'] = _formatApiDate(startDate);
      }
      if (endDate != null) {
        queryParameters['end_date'] = _formatApiDate(endDate);
      }
    }

    final response = await _apiClient.get(
      ApiEndpoints.dashboardSalesman,
      token: token,
      queryParameters: queryParameters,
    );

    return SalesmanDashboardResponseModel.fromJson(response);
  }

  String _formatApiDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
