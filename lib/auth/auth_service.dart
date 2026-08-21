import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool get isLoggedIn => _auth.currentUser != null;

  static String? get userName => _auth.currentUser?.displayName;

  static String? get userEmail => _auth.currentUser?.email;

  static String? get userId => _auth.currentUser?.uid;

  static Future<void> init() async {

  }

  static Future<Map<String, dynamic>> checkHealth() async {
    return FirebaseService.checkHealth();
  }

  static Future<String?> register(
      String name,
      String email,
      String password) async {
    final result = await registerWithDetails(name, email, password);

    if (result['success'] == true) {
      return null;
    }

    return result['error'];
  }

  static Future<Map<String, dynamic>> registerWithDetails(
      String name,
      String email,
      String password) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timed out. Please check your internet and try again.'),
          );

      final user = credential.user;

      if (user != null) {
        
        Future(() async {
          try {
            await user.updateDisplayName(name.trim())
                .timeout(const Duration(seconds: 5));
            await FirebaseService.saveUserProfile(
              uid: user.uid,
              name: name,
              email: email.trim(),
            ).timeout(const Duration(seconds: 5));
          } catch (_) {
            
          }
        });
      }

      return {
        'success': true,
        'message': 'Account created successfully'
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Registration failed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  static Future<String?> login(
      String email,
      String password) async {
    final result = await loginWithDetails(email, password);

    if (result['success'] == true) {
      return null;
    }

    return result['error'];
  }

  static Future<Map<String, dynamic>> loginWithDetails(
      String email,
      String password) async {
    try {
      await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timed out. Please check your internet and try again.'),
          );

      return {
        'success': true,
        'message': 'Login successful'
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Login failed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}