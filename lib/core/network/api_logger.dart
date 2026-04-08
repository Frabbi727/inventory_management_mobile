import 'dart:convert';

import 'package:flutter/foundation.dart';

class ApiLogger {
  const ApiLogger();

  void logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[API REQUEST] $method $uri');
    debugPrint('[API REQUEST HEADERS] ${_encode(headers)}');
    if (body != null) {
      debugPrint('[API REQUEST BODY] ${_encode(body)}');
    }
  }

  void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[API RESPONSE] $method $uri');
    debugPrint('[API RESPONSE STATUS] $statusCode');
    debugPrint('[API RESPONSE HEADERS] ${_encode(headers)}');
    debugPrint('[API RESPONSE BODY] ${body.isEmpty ? '{}' : body}');
  }

  void logErrorResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[API ERROR] $method $uri');
    debugPrint('[API ERROR STATUS] $statusCode');
    debugPrint('[API ERROR HEADERS] ${_encode(headers)}');
    debugPrint('[API ERROR BODY] ${body.isEmpty ? '{}' : body}');
  }

  String _encode(Object data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
