import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/logout_response_model.dart';
import '../models/profile_response_model.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
    );

    return LoginResponseModel.fromJson(response);
  }

  Future<ProfileResponseModel> getCurrentProfile(String token) async {
    final response = await _apiClient.get(ApiEndpoints.me, token: token);

    return ProfileResponseModel.fromJson(response);
  }

  Future<LogoutResponseModel> logout(String token) async {
    final response = await _apiClient.post(ApiEndpoints.logout, token: token);

    return LogoutResponseModel.fromJson(response);
  }
}
