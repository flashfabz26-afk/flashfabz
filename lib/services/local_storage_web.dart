import 'dart:async';
import 'dart:html' as html;

class LocalStorageHelper {
  static Future<void> save(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  static Future<String?> load(String key) async {
    return html.window.localStorage[key];
  }

  static Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }
}
