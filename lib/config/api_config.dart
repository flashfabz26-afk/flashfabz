import 'package:flutter/foundation.dart';

class ApiConfig {
  
  static const String _envApiUrl = String.fromEnvironment('API_URL');


  static String _activeBaseUrl = '';


  static String get baseUrl {
    if (_activeBaseUrl.isNotEmpty) {
      return _activeBaseUrl;
    }
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:5000/api';
    }
  }

  
  static List<String> get candidateBaseUrls {
    if (_envApiUrl.isNotEmpty) {
      return [_envApiUrl];
    }

    if (kIsWeb) {
      return ['http://localhost:5000/api', 'http://127.0.0.1:5000/api'];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return ['http://10.0.2.2:5000/api', 'http://10.0.2.2:5000/api'];
      default:
        return ['http://127.0.0.1:5000/api', 'http://localhost:5000/api'];
    }
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }


  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  
  static const Duration requestTimeout = Duration(seconds: 10);
}
