import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Centralized runtime configuration for connecting Flutter to the Spring Boot backend.
abstract final class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Base API URL (e.g. `http://localhost:8080/api` or `http://10.0.2.2:8080/api` on Android emulator).
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }
}
