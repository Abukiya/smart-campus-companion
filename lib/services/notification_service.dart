import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Initialize — call this in main() after Firebase.initializeApp()
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notifications for foreground messages
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _local.initialize(settings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  // Get FCM token for this device
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // Show local notification when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'campus_companion_channel',
          'Campus Companion',
          channelDescription: 'Campus alerts and announcements',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF1D9E75),
        ),
      ),
    );
  }

  // Handle notification tap (navigate to announcement)
  void _handleMessageTap(RemoteMessage message) {
    // Navigation handling — can be extended with go_router
    final announcementId = message.data['announcement_id'];
    if (announcementId != null) {
      // TODO: Navigate to announcement detail
      // RouterService.navigateTo('/announcements/$announcementId');
    }
  }

  // Subscribe to department topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic.replaceAll(' ', '_').toLowerCase());
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic.replaceAll(' ', '_').toLowerCase());
  }
}

// Required: top-level function for background FCM messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message silently
}
