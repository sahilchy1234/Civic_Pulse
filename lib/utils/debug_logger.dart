import 'package:flutter/foundation.dart';

/// Centralized debugging utility for the CivicSense app
class DebugLogger {
  static const String _defaultTag = 'CivicSense';
  
  /// Log a debug message with optional tag and error
  static void log(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagStr = tag != null ? '[$tag]' : '[$_defaultTag]';
      final errorStr = error != null ? ' - ERROR: $error' : '';
      final stackStr = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
      
      print('$timestamp $tagStr $message$errorStr$stackStr');
    }
  }
  
  /// Log authentication related messages
  static void auth(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'AUTH', error: error, stackTrace: stackTrace);
  }
  
  /// Log Firestore related messages
  static void firestore(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'FIRESTORE', error: error, stackTrace: stackTrace);
  }
  
  /// Log UI related messages
  static void ui(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'UI', error: error, stackTrace: stackTrace);
  }
  
  /// Log network related messages
  static void network(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'NETWORK', error: error, stackTrace: stackTrace);
  }
  
  /// Log Firebase related messages
  static void firebase(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'FIREBASE', error: error, stackTrace: stackTrace);
  }
  
  /// Log Google Sign-In related messages
  static void google(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'GOOGLE', error: error, stackTrace: stackTrace);
  }
  
  /// Log location related messages
  static void location(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'LOCATION', error: error, stackTrace: stackTrace);
  }
  
  /// Log notification related messages
  static void notification(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'NOTIFICATION', error: error, stackTrace: stackTrace);
  }
  
  /// Log user action related messages
  static void userAction(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'USER_ACTION', error: error, stackTrace: stackTrace);
  }
  
  /// Log app lifecycle related messages
  static void lifecycle(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'LIFECYCLE', error: error, stackTrace: stackTrace);
  }
  
  /// Log performance related messages
  static void performance(String message, {dynamic error, StackTrace? stackTrace}) {
    log(message, tag: 'PERFORMANCE', error: error, stackTrace: stackTrace);
  }
}

/// Global debug function for backward compatibility
void debugLog(String message, {String? tag, dynamic error}) {
  DebugLogger.log(message, tag: tag, error: error);
}
