
import 'dart:convert';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';

class AuthAPI {
  final http.Client client;

  AuthAPI({http.Client? client})
      : client = client ?? http.Client();

  String get _baseUrl {
    final apiBase = AppConfig.apiBaseUrl;
    if (apiBase.isNotEmpty) {
      return '$apiBase/auth';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/auth';
    }
    return 'http://localhost:8080/api/auth';
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login');

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': identifier,
        'nickname': identifier,
        'passwordHash': password,
      }),
    );

    final decoded = response.body.isNotEmpty
        ? jsonDecode(utf8.decode(response.bodyBytes))
        : <String, dynamic>{};

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Dữ liệu user trả về không đúng định dạng JSON Object',
      );
    } else {
      final errorMessage = decoded is Map<String, dynamic>
          ? (decoded['message'] ??
          decoded['error'] ??
          'Đăng nhập thất bại (${response.statusCode})')
          : 'Đăng nhập thất bại (${response.statusCode})';

      throw Exception(errorMessage);
    }
  }
}
