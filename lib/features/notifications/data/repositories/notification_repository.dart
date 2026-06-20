import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of notifications for a specific user, sorted descending by creation time
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Write a notification to Firestore and send a direct FCM push notification to the user's registered devices
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // 1. Write the notification to Firestore (for In-App notifications inside the app)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Fetch the recipient user's registered FCM tokens from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('fcmTokens')) {
          final List<dynamic> rawTokens = userData['fcmTokens'] ?? [];
          final List<String> fcmTokens = rawTokens.map((t) => t.toString()).toList();
          
          if (fcmTokens.isNotEmpty) {
            await _sendFcmPush(fcmTokens, title, body);
          }
        }
      }
    } catch (e) {
      // Fail silently to keep primary database transactions safe and unblocked
      print('Error writing/sending notification: $e');
    }
  }

  // Helper method to send a legacy FCM HTTP push message directly to device tokens
  Future<void> _sendFcmPush(List<String> tokens, String title, String body) async {
    if (AppConstants.fcmServerKey.isEmpty || AppConstants.fcmServerKey == 'YOUR_SERVER_KEY') {
      print('=== [FCM] FCM Server Key is not configured in AppConstants. Skipping push delivery. ===');
      return;
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('https://fcm.googleapis.com/fcm/send'));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'key=${AppConstants.fcmServerKey}');

      final payload = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'title': title,
          'body': body,
        },
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      
      final responseBody = await response.transform(utf8.decoder).join();
      print('=== [FCM] Direct FCM Push Response: ${response.statusCode} - $responseBody ===');
    } catch (e) {
      print('=== [FCM] Error sending direct FCM push: $e ===');
    } finally {
      client.close();
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all unread notifications for a user as read using a batch commit
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications for a user using a batch commit
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  // Request notification permissions, fetch the FCM token and append it to the user's Firestore document
  Future<void> updateFcmToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // iOS requires APNS token before fetching FCM token.
        // It can take some time to set during background connection on startup.
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          String? apnsToken = await messaging.getAPNSToken();
          int retries = 0;
          while (apnsToken == null && retries < 15) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await messaging.getAPNSToken();
            retries++;
          }
          if (apnsToken == null) {
            print('=== [FCM] APNS token not set yet. Token registration will resume on refresh. ===');
            // Still register token refresh stream in case it arrives later
            _subscribeToTokenRefresh(userId);
            return;
          }
        }

        final token = await messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmTokens': FieldValue.arrayUnion([token]),
          });
          print('=== [FCM] Token updated in Firestore for user $userId: $token ===');
        }
        
        // Also subscribe to refresh stream for future updates
        _subscribeToTokenRefresh(userId);
      } else {
        print('=== [FCM] User declined push notification permissions ===');
      }
    } catch (e) {
      print('=== [FCM] Error updating FCM token: $e ===');
    }
  }

  // Subscribe to token refresh stream
  void _subscribeToTokenRefresh(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        });
        print('=== [FCM] Token refreshed and saved in Firestore for user $userId: $newToken ===');
      } catch (e) {
        print('=== [FCM] Error saving refreshed token: $e ===');
      }
    });
  }

  // Remove the device's FCM token from the user's Firestore document upon logout
  Future<void> removeFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
        print('=== [FCM] Token removed from Firestore for user $userId ===');
      }
    } catch (e) {
      print('=== [FCM] Error removing FCM token: $e ===');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Stream provider for unread / read notifications list
final userNotificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUserNotifications(userId);
});
