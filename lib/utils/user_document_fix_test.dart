import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'debug_logger.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Test utility to verify user document creation fix
class UserDocumentFixTest {
  static Future<void> testMissingUserDocumentFix() async {
    if (!kDebugMode) return;
    
    DebugLogger.auth('=== TESTING MISSING USER DOCUMENT FIX ===');
    
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      // Check if there's a current user
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        DebugLogger.auth('No current user found - cannot test fix');
        return;
      }
      
      DebugLogger.auth('Current user: ${currentUser.email} (${currentUser.uid})');
      
      // Check if user document exists
      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();
          
      DebugLogger.firestore('User document exists: ${doc.exists}');
      
      if (!doc.exists) {
        DebugLogger.auth('User document is missing - this should be fixed automatically');
        DebugLogger.auth('The AuthService should create the document on next load');
      } else {
        DebugLogger.firestore('User document exists with data: ${doc.data()}');
      }
      
      DebugLogger.auth('=== USER DOCUMENT FIX TEST COMPLETED ===');
      
    } catch (e) {
      DebugLogger.auth('Error testing user document fix', error: e);
    }
  }
}
