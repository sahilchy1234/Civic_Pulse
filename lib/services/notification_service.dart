import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        print('FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          notifyListeners();
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages (when app is in background)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    // Handle foreground message (show in-app notification, etc.)
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Received background message: ${message.messageId}');
    // Handle background message (navigate to specific screen, etc.)
  }

  Future<void> saveTokenToUser(String userId) async {
    if (_fcmToken == null) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': _fcmToken,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // In a real app, you would use Firebase Cloud Functions
      // or a backend service to send notifications
      // This is a placeholder for the notification logic
      
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> sendNewIssueNotification(String issueId, String issueTitle) async {
    try {
      // Get all authority users
      final authorityUsers = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.authorityRole)
          .get();

      for (final doc in authorityUsers.docs) {
        final userData = doc.data();
        final fcmToken = userData['fcmToken'] as String?;
        
        if (fcmToken != null) {
          await sendNotificationToUser(
            userId: doc.id,
            title: 'New Issue Reported',
            body: issueTitle,
            data: {
              'type': AppConstants.newIssueNotification,
              'issueId': issueId,
            },
          );
        }
      }
    } catch (e) {
      print('Error sending new issue notification: $e');
    }
  }

  Future<void> sendStatusUpdateNotification(
    String userId, String issueTitle, String newStatus) async {
    try {
      await sendNotificationToUser(
        userId: userId,
        title: 'Issue Status Updated',
        body: '$issueTitle is now $newStatus',
        data: {
          'type': AppConstants.statusUpdateNotification,
          'status': newStatus,
        },
      );
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  Future<void> sendUpvoteNotification(
    String userId, String issueTitle) async {
    try {
      await sendNotificationToUser(
        userId: userId,
        title: 'Your Issue Got Upvoted!',
        body: '$issueTitle received a new upvote',
        data: {
          'type': AppConstants.upvoteNotification,
        },
      );
    } catch (e) {
      print('Error sending upvote notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}
