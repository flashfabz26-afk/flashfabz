import 'package:flutter/foundation.dart';
import '../utils/gerber_parser.dart';
class GerberApiService {
  static Future<GerberParseResult> uploadGerber(
    String fileName,
    List<int> bytes,
  ) async {
    
    try {
      final result = await compute(_parseGerber, bytes);
      return result;
    } on Exception {
      rethrow; 
    }
  }
  static GerberParseResult _parseGerber(List<int> bytes) {
    return GerberParser.parseZipBytes(bytes);
  }
}
