import 'dart:async';

class LocalStorageHelper {
  static Future<void> save(String key, String value) async {
    throw UnsupportedError('LocalStorageHelper.save is not supported on this platform.');
  }

  static Future<String?> load(String key) async {
    throw UnsupportedError('LocalStorageHelper.load is not supported on this platform.');
  }

  static Future<void> delete(String key) async {
    throw UnsupportedError('LocalStorageHelper.delete is not supported on this platform.');
  }
}
