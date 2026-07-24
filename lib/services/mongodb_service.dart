import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MongoDbService {
  // Base URL for the MongoDB REST API server
  // Default to localhost for web/desktop. Change to 10.0.2.2 if testing on Android Emulator.
  static String baseUrl = 'http://localhost:5000/api';

  static String? _authToken;
  static Map<String, dynamic>? _currentUser;

  static bool get isLoggedIn => _currentUser != null;
  static String? get userEmail => _currentUser?['email'];
  static String? get userName => _currentUser?['name'];
  static String? get userId => _currentUser?['id'];
  static String? get authToken => _authToken;

  /// Checks if the backend server and MongoDB are connected and healthy
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'databaseStatus': data['databaseStatus'] ?? 'Unknown',
          'message': 'Connected to MongoDB Backend',
        };
      }
      return {
        'success': false,
        'databaseStatus': 'Disconnected',
        'message': 'Backend returned status ${response.statusCode}',
      };
    } catch (e) {
      if (kDebugMode) {
        print('MongoDB Health Check Failed: $e');
      }
      return {
        'success': false,
        'databaseStatus': 'Offline',
        'message': 'Could not connect to MongoDB server at $baseUrl. Ensure node server is running.',
      };
    }
  }

  /// Register a user in MongoDB
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _authToken = data['token'];
        _currentUser = data['user'];
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed.'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error connecting to MongoDB backend. Is the server running?',
      };
    }
  }

  /// Login a user with MongoDB
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);


      if (response.statusCode == 200) {
        _authToken = data['token'];
        _currentUser = data['user'];
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed.'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error connecting to MongoDB backend. Is the server running?',
      };
    }
  }

  /// Save a PCB Order into MongoDB database
  static Future<Map<String, dynamic>> saveOrder({
    required String userEmail,
    required String fileName,
    required int layerCount,
    required double boardWidth,
    required double boardHeight,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userEmail': userEmail,
          'fileName': fileName,
          'layerCount': layerCount,
          'boardWidth': boardWidth,
          'boardHeight': boardHeight,
          'quantity': quantity,
          'totalPrice': totalPrice,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'order': data['order']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to save order.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Logout current user
  static void logout() {
    _authToken = null;
    _currentUser = null;
  }
}
