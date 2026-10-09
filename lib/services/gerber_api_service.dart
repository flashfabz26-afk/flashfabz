import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/gerber_parser.dart';

class GerberApiService {
  static Future<GerberParseResult> uploadGerber(
    String fileName,
    List<int> bytes, {
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Local parse
      final result = await compute(_parseGerber, bytes);
      
      // 2. Upload to Firebase
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;
          
          // Create Firestore doc reference to get uploadId
          final docRef = FirebaseFirestore.instance.collection('gerber_uploads').doc();
          final uploadId = docRef.id;

          // Storage path: gerber_files/{userId}/{uploadId}/{fileName}
          final storageRef = FirebaseStorage.instance.ref();
          final gerberRef = storageRef.child('gerber_files/$userId/$uploadId/$fileName');
          
          // Start upload
          final uploadTask = gerberRef.putData(Uint8List.fromList(bytes));
          
          if (onProgress != null) {
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              onProgress(progress);
            });
          }

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          
          // Save metadata to Firestore
          await docRef.set({
            'fileName': fileName,
            'downloadUrl': downloadUrl,
            'storagePath': gerberRef.fullPath,
            'fileSize': bytes.length,
            'uploadDate': FieldValue.serverTimestamp(),
            'userId': userId,
            'uploadStatus': 'success',
          });
        }
      } catch (e) {
        debugPrint('Firebase Storage upload failed: $e');
      }

      return result;
    } on Exception {
      rethrow; 
    }
  }

  static GerberParseResult _parseGerber(List<int> bytes) {
    return GerberParser.parseZipBytes(bytes);
  }
}
