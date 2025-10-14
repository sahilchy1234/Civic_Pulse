import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Test Firebase Storage connectivity and configuration
  static Future<Map<String, dynamic>> testStorageConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'error': null,
      'bucket': null,
      'canWrite': false,
      'canRead': false,
      'details': <String>[],
    };

    try {
      result['details'].add('Initializing Firebase Storage...');
      
      // Get storage bucket info
      final bucket = _storage.bucket;
      result['bucket'] = bucket;
      result['details'].add('Storage bucket: $bucket');
      
      // Test basic connectivity by creating a reference
      final testRef = _storage.ref().child('test/connection_test.txt');
      result['details'].add('Created test reference: ${testRef.fullPath}');
      
      // Test write capability with a small test file
      try {
        final testData = 'Firebase Storage test - ${DateTime.now()}';
        final testUpload = testRef.putString(testData);
        await testUpload.timeout(const Duration(seconds: 10));
        result['canWrite'] = true;
        result['details'].add('✅ Write test successful');
        
        // Test read capability
        try {
          final downloadUrl = await testRef.getDownloadURL().timeout(const Duration(seconds: 10));
          result['canRead'] = true;
          result['details'].add('✅ Read test successful');
          result['details'].add('Download URL: $downloadUrl');
          
          // Clean up test file
          try {
            await testRef.delete().timeout(const Duration(seconds: 5));
            result['details'].add('✅ Test file cleaned up');
          } catch (e) {
            result['details'].add('⚠️ Could not clean up test file: $e');
          }
        } catch (e) {
          result['canRead'] = false;
          result['error'] = 'Read test failed: $e';
          result['details'].add('❌ Read test failed: $e');
        }
      } catch (e) {
        result['canWrite'] = false;
        result['error'] = 'Write test failed: $e';
        result['details'].add('❌ Write test failed: $e');
      }
      
      result['success'] = result['canWrite'] && result['canRead'];
      
    } catch (e) {
      result['error'] = 'Storage connection failed: $e';
      result['details'].add('❌ Connection failed: $e');
    }
    
    return result;
  }

  /// Get Firebase Storage configuration info
  static Map<String, dynamic> getStorageInfo() {
    return {
      'bucket': _storage.bucket,
      'app': _storage.app.name,
      'maxUploadRetryTime': _storage.maxUploadRetryTime.inSeconds,
      'maxOperationRetryTime': _storage.maxOperationRetryTime.inSeconds,
    };
  }

  /// Validate image file before upload
  static Map<String, dynamic> validateImageFile(String filePath, int fileSize) {
    final result = <String, dynamic>{
      'valid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check file size (limit to 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      result['valid'] = false;
      result['errors'].add('File size too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB (max: 10MB)');
    } else if (fileSize > 5 * 1024 * 1024) { // 5MB
      result['warnings'].add('Large file size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
    }

    // Check file extension
    final extension = filePath.toLowerCase().split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      result['valid'] = false;
      result['errors'].add('Unsupported file type: .$extension');
    }

    // Check minimum file size (avoid empty files)
    const minSize = 1024; // 1KB
    if (fileSize < minSize) {
      result['valid'] = false;
      result['errors'].add('File too small: ${fileSize} bytes (min: 1KB)');
    }

    return result;
  }

  /// Generate a safe filename for upload
  static String generateSafeFileName(String userId, String originalExtension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'issue_images/${userId}_${timestamp}_$random.$originalExtension';
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  /// Debug Firebase Storage configuration
  static void debugStorageConfig() {
    if (kDebugMode) {
      print('🔍 Firebase Storage Debug Info:');
      final info = getStorageInfo();
      info.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }
}
