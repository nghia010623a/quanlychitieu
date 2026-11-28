import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/auth_session.dart';

/// Exception thrown when an HTTP request to the Spring Boot backend fails.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Lightweight HTTP JSON client targeting the Spring Boot backend.
class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    AuthSession? authSession,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _authSession = authSession ?? AuthSession.instance,
        _timeout = timeout ?? AppConfig.requestTimeout;

  final http.Client _client;
  final String _baseUrl;
  final AuthSession _authSession;
  final Duration _timeout;

  Uri buildUri(String path, [Map<String, String?>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final rawUri = Uri.parse('$_baseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return rawUri;
    }
    final filtered = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        filtered[key] = value;
      }
    });
    return filtered.isEmpty
        ? rawUri
        : rawUri.replace(queryParameters: filtered);
  }

  Map<String, String> _buildHeaders({bool hasBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (hasBody) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    final userId = _authSession.userId;
    if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      () => _client.get(
        buildUri(path, queryParameters),
        headers: _buildHeaders(),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      () => _client.post(
        buildUri(path, queryParameters),
        headers: _buildHeaders(hasBody: true),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      () => _client.put(
        buildUri(path, queryParameters),
        headers: _buildHeaders(hasBody: true),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      () => _client.patch(
        buildUri(path, queryParameters),
        headers: _buildHeaders(hasBody: true),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<void> delete(
    String path, {
    Map<String, String?>? queryParameters,
  }) async {
    await _send(
      () => _client.delete(
        buildUri(path, queryParameters),
        headers: _buildHeaders(),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        message: 'Kết nối tới máy chủ quá thời gian. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw ApiException(
        message:
            'Không thể kết nối tới máy chủ ($_baseUrl). Hãy kiểm tra Backend đã chạy chưa.',
      );
    } catch (e) {
      throw ApiException(
        message: 'Lỗi kết nối mạng tới máy chủ ($_baseUrl): $e',
      );
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      final rawText = utf8.decode(response.bodyBytes);
      if (rawText.trim().isNotEmpty) {
        try {
          decoded = jsonDecode(rawText);
        } catch (_) {
          decoded = rawText;
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded is Map<String, dynamic>
        ? (decoded['message'] ??
                decoded['error'] ??
                'Yêu cầu thất bại (${response.statusCode})')
            .toString()
        : 'Yêu cầu thất bại (${response.statusCode})';

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
    );
  }
}
