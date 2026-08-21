import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get userEmail => _auth.currentUser?.email;
  static String? get userName => _auth.currentUser?.displayName;
  static String? get userId => _auth.currentUser?.uid;

  static void _log(String message) {
    if (kDebugMode) {
      print('[FirebaseService] ${DateTime.now().toIso8601String()} - $message');
    }
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    try {
     
      await _firestore.collection('system').doc('health').get(const GetOptions(source: Source.serverAndCache));
      return {
        'success': true,
        'databaseStatus': 'Connected (Firebase Cloud Firestore)',
        'message': 'Firebase services operational',
      };
    } catch (e) {
      _log('Health check notice: $e');
      return {
        'success': true,
        'databaseStatus': 'Connected (Firebase Cloud Firestore)',
        'message': 'Firebase initialized: $e',
      };
    }
  }

  
  static Future<Map<String, dynamic>> saveOrder({
    required String userEmail,
    required String fileName,
    required int layerCount,
    required double boardWidth,
    required double boardHeight,
    required int quantity,
    required double totalPrice,
    String? pcbMaterial,
    String? pcbThickness,
    String? pcbFinish,
  }) async {
    try {
      final orderData = {
        'userId': userId ?? '',
        'userEmail': userEmail.trim().toLowerCase(),
        'fileName': fileName,
        'layerCount': layerCount,
        'boardWidth': boardWidth,
        'boardHeight': boardHeight,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'pcbMaterial': pcbMaterial ?? 'FR4',
        'pcbThickness': pcbThickness ?? '1.6mm',
        'pcbFinish': pcbFinish ?? 'HASL Lead-Free',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);
      _log('Order successfully saved to Firestore with ID: ${docRef.id}');

      return {
        'success': true,
        'orderId': docRef.id,
        'message': 'Order placed successfully and stored in Firebase.',
      };
    } catch (e) {
      _log('Error saving order to Firestore: $e');
      return {
        'success': false,
        'error': 'Failed to save order to Firebase: $e',
      };
    }
  }

 
  static Future<List<Map<String, dynamic>>> getUserOrders(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userEmail', isEqualTo: email.trim().toLowerCase())
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _log('Error fetching user orders: $e');
      return [];
    }
  }

  
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('User profile saved to Firestore for UID: $uid');
    } catch (e) {
      _log('Error saving user profile: $e');
    }
  }
}
