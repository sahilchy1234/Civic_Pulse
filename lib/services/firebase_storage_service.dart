import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file to Firebase Storage
  static Future<String?> uploadFile(
    File file, {
    required String userId,
    String? customPath,
    String? fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      print('🚀 Starting Firebase Storage upload...');
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        print('❌ File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
        throw Exception('File size exceeds 10MB limit');
      }
      
      // Generate filename if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path).substring(1).toLowerCase();
      final finalFileName = fileName ?? '${userId}_${timestamp}.$extension';
      
      // Create storage path
      final storagePath = customPath ?? 'issue_images';
      final fullPath = '$storagePath/$finalFileName';
      
      print('📁 Uploading to: $fullPath');
      print('📏 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      // Create reference
      final ref = _storage.ref().child(fullPath);
      
      // Upload file with progress tracking
      final uploadTask = ref.putFile(file);
      
      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
          print('📊 Firebase Progress: ${(progress * 100).toStringAsFixed(1)}%');
        });
      }
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Firebase upload successful: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Firebase upload error: $e');
      rethrow;
    }
  }

  /// Test Firebase Storage connection
  static Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'error': null,
      'details': <String>[],
    };

    try {
      result['details'].add('Testing Firebase Storage connection...');
      
      // Test by trying to get reference (this validates connection)
      final ref = _storage.ref().child('test_connection');
      
      // Try to get metadata (this will fail if no file exists, but connection works)
      try {
        await ref.getMetadata();
        result['details'].add('✅ Firebase Storage connection successful');
        result['success'] = true;
      } catch (e) {
        // If we get here, connection works but file doesn't exist (expected)
        if (e.toString().contains('object-not-found')) {
          result['details'].add('✅ Firebase Storage connection successful (test file not found - expected)');
          result['success'] = true;
        } else {
          throw e;
        }
      }
      
    } catch (e) {
      result['error'] = e.toString();
      result['details'].add('❌ Firebase Storage connection failed: $e');
    }
    
    return result;
  }

  /// Delete file from Firebase Storage
  static Future<bool> deleteFile(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
      print('✅ Firebase file deleted: $filePath');
      return true;
    } catch (e) {
      print('❌ Failed to delete Firebase file: $e');
      return false;
    }
  }
}
