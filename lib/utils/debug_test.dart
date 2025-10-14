import 'package:flutter/foundation.dart';
import 'debug_logger.dart';

/// Test class to verify debugging functionality
class DebugTest {
  static void runAllTests() {
    if (kDebugMode) {
      print('=== RUNNING DEBUG TESTS ===');
      
      // Test basic logging
      DebugLogger.log('Basic log test');
      DebugLogger.auth('Authentication test');
      DebugLogger.firestore('Firestore test');
      DebugLogger.ui('UI test');
      DebugLogger.firebase('Firebase test');
      DebugLogger.google('Google test');
      DebugLogger.network('Network test');
      DebugLogger.location('Location test');
      DebugLogger.notification('Notification test');
      DebugLogger.userAction('User action test');
      DebugLogger.lifecycle('Lifecycle test');
      DebugLogger.performance('Performance test');
      
      // Test error logging
      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        DebugLogger.auth('Test error logging', error: e, stackTrace: stackTrace);
      }
      
      print('=== DEBUG TESTS COMPLETED ===');
    }
  }
}
