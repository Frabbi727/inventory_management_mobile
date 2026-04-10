import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../errors/api_exception.dart';
import 'api_logger.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, ApiLogger? apiLogger})
    : _httpClient = httpClient ?? http.Client(),
      _apiLogger = apiLogger ?? const ApiLogger();

  final http.Client _httpClient;
  final ApiLogger _apiLogger;

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final headers = _buildHeaders(token: token);
    _apiLogger.logRequest(method: 'GET', uri: uri, headers: headers);
    final response = await _httpClient.get(uri, headers: headers);

    return _handleResponse(method: 'GET', uri: uri, response: response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final headers = _buildHeaders(token: token);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    _apiLogger.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body ?? <String, dynamic>{},
    );
    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: encodedBody,
    );

    return _handleResponse(method: 'POST', uri: uri, response: response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final headers = _buildHeaders(token: token);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    _apiLogger.logRequest(
      method: 'PUT',
      uri: uri,
      headers: headers,
      body: body ?? <String, dynamic>{},
    );
    final response = await _httpClient.put(
      uri,
      headers: headers,
      body: encodedBody,
    );

    return _handleResponse(method: 'PUT', uri: uri, response: response);
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

  Map<String, dynamic> _handleResponse({
    required String method,
    required Uri uri,
    required http.Response response,
  }) {
    final responseBody = response.body.trim();
    final decodedBody = responseBody.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _apiLogger.logResponse(
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        headers: response.headers,
        body: responseBody,
      );
      return decodedBody;
    }

    _apiLogger.logErrorResponse(
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      headers: response.headers,
      body: responseBody,
    );

    throw ApiException(
      message: decodedBody['message'] as String? ?? 'Request failed.',
      statusCode: response.statusCode,
      errors: decodedBody['errors'] as Map<String, dynamic>?,
    );
  }
}
