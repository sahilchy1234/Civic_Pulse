import 'package:firebase_storage/firebase_storage.dart';

/// Simple Firebase Storage test that you can call from anywhere in your app
class SimpleStorageTest {
  static Future<void> runQuickTest() async {
    print('🧪 Quick Firebase Storage Test');
    print('=' * 40);
    
    try {
      // 1. Initialize storage
      final storage = FirebaseStorage.instance;
      print('✅ Storage initialized');
      print('📦 Bucket: ${storage.bucket}');
      
      // 2. Create a simple test reference
      final testRef = storage.ref().child('test/quick_test.txt');
      print('📁 Test reference: ${testRef.fullPath}');
      
      // 3. Upload a simple string
      print('⬆️ Uploading test data...');
      final uploadTask = testRef.putString('Hello Firebase Storage!');
      
      // 4. Wait for upload
      final snapshot = await uploadTask.timeout(const Duration(seconds: 10));
      print('✅ Upload completed');
      
      // 5. Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $downloadUrl');
      
      // 6. Clean up
      await snapshot.ref.delete();
      print('🗑️ Test file deleted');
      
      print('🎉 QUICK TEST PASSED! Firebase Storage is working correctly.');
      
    } catch (e) {
      print('❌ QUICK TEST FAILED: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (e.toString().contains('object-not-found')) {
        print('💡 This suggests a path or bucket access issue');
      } else if (e.toString().contains('unauthorized')) {
        print('💡 This suggests a permissions/authentication issue');
      } else if (e.toString().contains('network')) {
        print('💡 This suggests a network connectivity issue');
      }
    }
    
    print('=' * 40);
  }
}
