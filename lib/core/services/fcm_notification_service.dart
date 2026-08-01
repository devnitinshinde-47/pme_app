import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Service managing Firebase Cloud Messaging (FCM) push notifications and local foreground banners.
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  static FcmNotificationService get instance => _instance;

  FcmNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository = NotificationRepository();
  Future<void>? _initialization;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pme_high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important live class and video updates.',
    importance: Importance.high,
  );

  /// Initialize Firebase & FCM Notification handling
  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Create Android Notification Channel
      if (Platform.isAndroid) {
        final androidNotifications = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidNotifications?.createNotificationChannel(_channel);
        // Android 13+ needs this explicit runtime permission request. The FCM
        // request alone is not reliable on every Android/plugin combination.
        await androidNotifications?.requestNotificationsPermission();
      }

      // Initialize Local Notifications Plugin
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Request FCM Permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM notification authorization: ${settings.authorizationStatus}');

      // Sync FCM Token with Spring Boot backend
      await syncTokenWithBackend();

      // Listen for Token Refresh
      messaging.onTokenRefresh.listen((newToken) async {
        final saved = await _notificationRepository.registerFcmToken(newToken);
        debugPrint('FCM token refresh synced: $saved');
      });

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint('FCM initialization failed: $error\n$stackTrace');
    }
  }

  /// Sync student FCM device token to Spring Boot backend
  Future<void> syncTokenWithBackend() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final saved = await _notificationRepository.registerFcmToken(fcmToken);
        debugPrint('FCM token synced: $saved');
      }
    } catch (error, stackTrace) {
      debugPrint('FCM token sync failed: $error\n$stackTrace');
    }
  }
}
