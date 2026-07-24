import '../services/mongodb_service.dart';

class AuthService {
  static bool get isLoggedIn => MongoDbService.isLoggedIn;

  static String? get userName => MongoDbService.userName;

  static String? get userEmail => MongoDbService.userEmail;

  /// Registers a user using MongoDB. Returns null on success or an error message string on failure.
  static Future<String?> register(String name, String email, String password) async {
    final mongoResult = await MongoDbService.register(
      name: name,
      email: email,
      password: password,
    );

    if (mongoResult['success'] == true) {
      return null; // Success with MongoDB
    }

    return mongoResult['error'] ?? 'Registration failed. Please check server connection.';
  }

  /// Logs in a user using MongoDB. Returns null on success or an error message string on failure.
  static Future<String?> login(String email, String password) async {
    final mongoResult = await MongoDbService.login(
      email: email,
      password: password,
    );

    if (mongoResult['success'] == true) {
      return null; // Success with MongoDB
    }

    return mongoResult['error'] ?? 'Login failed. Please check server connection.';
  }

  /// Logs out the current user.
  static Future<void> logout() async {
    MongoDbService.logout();
  }
}
