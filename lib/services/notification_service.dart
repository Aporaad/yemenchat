// =============================================================================
// YemenChat - Notification Service
// =============================================================================
// Handles Firebase Cloud Messaging and Local Notifications.
// =============================================================================

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  // The local notification will be shown automatically by the system
}

/// Service class for handling push notifications
class NotificationService {
  // Firebase Messaging instance
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Flutter Local Notifications instance
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'yemenchat_messages', // id
    'Chat Messages', // name
    description: 'Notifications for new chat messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Callback for when user taps a notification
  void Function(RemoteMessage)? onMessageTapped;

  // Callback for foreground messages
  void Function(RemoteMessage)? onForegroundMessage;

  // Callback for local notification tap
  void Function(String? payload)? onLocalNotificationTapped;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission
    await requestPermission();

    // Get FCM token
    final token = await getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
    }

    // Configure message handlers
    _configureMessageHandlers();
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped with payload: ${response.payload}');
        if (onLocalNotificationTapped != null) {
          onLocalNotificationTapped!(response.payload);
        }
      },
    );

    // Create notification channel for Android (skip on web)
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    // Request FCM permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Request local notification permission on Android 13+ (skip on web)
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ===========================================================================
  // MESSAGE HANDLERS
  // ===========================================================================

  /// Configure message handlers for different app states
  void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');

      if (onForegroundMessage != null) {
        onForegroundMessage!(message);
      }

      // Show local notification with sound and popup
      _showLocalNotification(message);
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.messageId}');

      if (onMessageTapped != null) {
        onMessageTapped!(message);
      }
    });
  }

  /// Check if app was opened from a notification
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  // ===========================================================================
  // LOCAL NOTIFICATION DISPLAY
  // ===========================================================================

  /// Show local notification with sound and popup
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Android notification details
      final androidNotificationDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        // Heads-up notification (popup)
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      // iOS notification details
      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Show notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'New Message',
        notification.body ?? 'You have a new message',
        notificationDetails,
        payload: message.data['chatId'] ?? '',
      );
    }
  }

  /// Show a custom notification (can be called from anywhere)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidNotificationDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
    );

    const iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ===========================================================================
  // TOPIC SUBSCRIPTION
  // ===========================================================================

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await requestPermission();
    }
  }

  /// Get current notification settings
  Future<NotificationSettings> getSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> isEnabled() async {
    final settings = await getSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }
}
