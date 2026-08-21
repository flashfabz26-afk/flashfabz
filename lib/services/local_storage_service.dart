import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'local_storage_stub.dart'
    if (dart.library.html) 'local_storage_web.dart'
    if (dart.library.io) 'local_storage_io.dart';

class LocalStorageService {
  static const String _sessionKey = 'lion_circuits_session';

  static Map<String, dynamic>? _cachedSession;

  
  static Future<void> saveSession(String? token, Map<String, dynamic>? user) async {
    if (token == null || user == null) return;
    
    final data = {
      'token': token,
      'user': user,
      'savedAt': DateTime.now().toIso8601String(),
    };
    _cachedSession = data;

    try {
      await LocalStorageHelper.save(_sessionKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageService] Error saving session: $e');
      }
    }
  }

 
  static Future<Map<String, dynamic>?> loadSession() async {
    if (_cachedSession != null) return _cachedSession;

    try {
      final content = await LocalStorageHelper.load(_sessionKey);
      if (content != null && content.isNotEmpty) {
        _cachedSession = jsonDecode(content);
        return _cachedSession;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageService] Error loading session: $e');
      }
    }
    return null;
  }


  static Future<void> clearSession() async {
    _cachedSession = null;
    try {
      await LocalStorageHelper.delete(_sessionKey);
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageService] Error clearing session: $e');
      }
    }
  }
}
