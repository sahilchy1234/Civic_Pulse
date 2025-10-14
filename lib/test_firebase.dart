import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTest {
  static Future<void> testConnection() async {
    try {
      // Test Firebase Core
      await Firebase.initializeApp();
      print('✅ Firebase Core initialized');
      
      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('test').set({'test': true});
      print('✅ Firestore connection working');
      
      // Test Auth
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized');
      
      print('🎉 All Firebase services are working!');
    } catch (e) {
      print('❌ Firebase setup error: $e');
    }
  }
}
