import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_storage_helper.dart';

/// Simple test script for Firebase Storage functionality
class FirebaseStorageTest {
  static Future<void> runTests() async {
    print('🧪 Starting Firebase Storage Tests...');
    print('=' * 50);
    
    // Test 1: Basic connection test
    print('\n📡 Test 1: Storage Connection Test');
    final connectionResult = await FirebaseStorageHelper.testStorageConnection();
    print('Success: ${connectionResult['success']}');
    print('Bucket: ${connectionResult['bucket']}');
    print('Can Write: ${connectionResult['canWrite']}');
    print('Can Read: ${connectionResult['canRead']}');
    if (connectionResult['error'] != null) {
      print('Error: ${connectionResult['error']}');
    }
    
    // Test 2: Storage info
    print('\n📊 Test 2: Storage Configuration Info');
    final storageInfo = FirebaseStorageHelper.getStorageInfo();
    storageInfo.forEach((key, value) {
      print('$key: $value');
    });
    
    // Test 3: File validation
    print('\n✅ Test 3: File Validation Tests');
    final testCases = [
      {'path': 'test.jpg', 'size': 1024},
      {'path': 'test.png', 'size': 5 * 1024 * 1024}, // 5MB
      {'path': 'test.txt', 'size': 2048}, // Wrong extension
      {'path': 'test.jpg', 'size': 11 * 1024 * 1024}, // Too large
      {'path': 'test.jpg', 'size': 500}, // Too small
    ];
    
    for (final testCase in testCases) {
      final validation = FirebaseStorageHelper.validateImageFile(
        testCase['path'] as String, 
        testCase['size'] as int
      );
      print('File: ${testCase['path']} (${FirebaseStorageHelper.formatFileSize(testCase['size'] as int)})');
      print('  Valid: ${validation['valid']}');
      if (validation['errors'].isNotEmpty) {
        print('  Errors: ${validation['errors']}');
      }
      if (validation['warnings'].isNotEmpty) {
        print('  Warnings: ${validation['warnings']}');
      }
    }
    
    // Test 4: Filename generation
    print('\n📝 Test 4: Filename Generation');
    final testExtensions = ['jpg', 'png', 'gif', 'webp'];
    for (final ext in testExtensions) {
      final filename = FirebaseStorageHelper.generateSafeFileName('test_user', ext);
      print('Generated: $filename');
    }
    
    print('\n🏁 Firebase Storage Tests Completed!');
    print('=' * 50);
  }
  
  /// Quick connectivity test
  static Future<bool> quickTest() async {
    try {
      final result = await FirebaseStorageHelper.testStorageConnection();
      return result['success'] == true;
    } catch (e) {
      print('Quick test failed: $e');
      return false;
    }
  }

  /// Test the exact upload path that's failing in your app
  static Future<void> testIssueImageUpload() async {
    print('🔍 Testing Issue Image Upload Path...');
    
    try {
      final storage = FirebaseStorage.instance;
      print('✅ Firebase Storage instance created');
      print('📦 Bucket: ${storage.bucket}');
      
      // Test the exact path structure your app uses
      final testUserId = 'test_user_123';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'issue_images/${testUserId}_${timestamp}.jpg';
      
      print('🎯 Testing path: $fileName');
      
      final ref = storage.ref().child(fileName);
      print('📁 Reference created: ${ref.fullPath}');
      
      // Create a simple test string instead of a file
      final testData = 'This is a test file for Firebase Storage upload';
      print('📝 Creating test upload...');
      
      final uploadTask = ref.putString(testData);
      print('⬆️ Upload task created');
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timed out');
        },
      );
      print('✅ Upload completed successfully!');
      
      // Test getting download URL
      print('🔗 Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Download URL: $downloadUrl');
      
      // Clean up test file
      print('🗑️ Cleaning up test file...');
      await snapshot.ref.delete();
      print('✅ Test file deleted');
      
      print('🎉 Issue image upload test PASSED!');
      
    } catch (e) {
      print('❌ Issue image upload test FAILED: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Provide specific error analysis
      if (e.toString().contains('object-not-found')) {
        print('💡 Analysis: The storage reference path is invalid or bucket is not accessible');
      } else if (e.toString().contains('unauthorized')) {
        print('💡 Analysis: Authentication or permission issue');
      } else if (e.toString().contains('network')) {
        print('💡 Analysis: Network connectivity issue');
      } else if (e.toString().contains('timeout')) {
        print('💡 Analysis: Upload is taking too long');
      }
    }
  }
}
