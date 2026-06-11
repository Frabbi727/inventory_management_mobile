import 'dart:convert';

import 'package:flutter/foundation.dart';

class ApiLogger {
  const ApiLogger();

  static const int _lineWidth = 72;

  void logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    if (!kDebugMode) return;

    final methodIcon = _methodIcon(method);
    _printTop('📤 REQUEST');
    _printLine('$methodIcon  $method  $uri');
    _printLabel('🔑  HEADERS');
    _printIndented(_encode(headers));
    if (body != null) {
      _printLabel('📦  BODY');
      _printIndented(_encode(body));
    }
    _printBottom();
  }

  void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    if (!kDebugMode) return;

    final methodIcon = _methodIcon(method);
    _printTop('✅ RESPONSE');
    _printLine('$methodIcon  $method  $uri');
    _printLine('🔢  $statusCode ${_statusText(statusCode)}');
    _printLabel('🔑  HEADERS');
    _printIndented(_encode(headers));
    _printLabel('📦  BODY');
    _printIndented(body.isEmpty ? '{}' : _tryPretty(body));
    _printBottom();
  }

  void logErrorResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    if (!kDebugMode) return;

    final methodIcon = _methodIcon(method);
    _printTop('❌ ERROR');
    _printLine('$methodIcon  $method  $uri');
    _printLine('🔢  $statusCode ${_statusText(statusCode)}');
    _printLabel('🔑  HEADERS');
    _printIndented(_encode(headers));
    _printLabel('📦  BODY');
    _printIndented(body.isEmpty ? '{}' : _tryPretty(body));
    _printBottom();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _printTop(String label) {
    final title = '╔══ $label ';
    final padding = '═' * (_lineWidth - title.length).clamp(0, _lineWidth);
    debugPrint('$title$padding');
  }

  void _printBottom() {
    debugPrint('╚${'═' * _lineWidth}');
  }

  void _printLine(String content) {
    debugPrint('║  $content');
  }

  void _printLabel(String label) {
    debugPrint('║');
    debugPrint('║  $label');
  }

  void _printIndented(String text) {
    for (final line in text.split('\n')) {
      debugPrint('║    $line');
    }
  }

  String _methodIcon(String method) {
    return switch (method.toUpperCase()) {
      'GET' => '🔍',
      'POST' => '📮',
      'PUT' => '📝',
      'PATCH' => '🔧',
      'DELETE' => '🗑️',
      _ => '🌐',
    };
  }

  String _statusText(int code) {
    return switch (code) {
      200 => 'OK',
      201 => 'Created',
      204 => 'No Content',
      301 => 'Moved Permanently',
      302 => 'Found',
      304 => 'Not Modified',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      409 => 'Conflict',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',
      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      _ => '',
    };
  }

  String _encode(Object data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _tryPretty(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }
}
