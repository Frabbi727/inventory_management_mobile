import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../errors/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(token: token),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(token: token),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _handleResponse(response);
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers[ApiConfig.protectedHeader] = '${ApiConfig.bearerPrefix} $token';
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = response.body.trim();
    final decodedBody = responseBody.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw ApiException(
      message: decodedBody['message'] as String? ?? 'Request failed.',
      statusCode: response.statusCode,
      errors: decodedBody['errors'] as Map<String, dynamic>?,
    );
  }
}
