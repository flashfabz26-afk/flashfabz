import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalStorageHelper {
  static const String _sessionFileName = 'lion_circuits_session.json';

  static Future<File> _getStorageFile() async {
    final tempDir = Directory.systemTemp;
    return File('${tempDir.path}/$_sessionFileName');
  }

  static Future<void> save(String key, String value) async {
    try {
      final file = await _getStorageFile();
      await file.writeAsString(value);
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageHelper-IO] Error saving session: $e');
      }
    }
  }

  static Future<String?> load(String key) async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageHelper-IO] Error loading session: $e');
      }
    }
    return null;
  }

  static Future<void> delete(String key) async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageHelper-IO] Error clearing session: $e');
      }
    }
  }
}
