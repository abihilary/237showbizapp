import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Use a GlobalKey to access the Navigator's context from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> setup() async {
    // 3. Initialize the local notifications plugin.
    // This tells the plugin what icon to use for notifications.
    // 'ic_notification' refers to the icon file in 'android/app/src/main/res/drawable/'.
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('ic_notification');

    const InitializationSettings settings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings,
      // This function is called when a user taps a notification that this plugin created.
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('flutter_local_notifications tapped with payload: ${response.payload}');
        // You can add navigation logic here based on the payload (e.g., a post ID).
      },
    );

    // Create the Android notification channel. This is mandatory for Android 8.0+.
    _createNotificationChannel();

    // 4. THIS IS THE FIX: Set up the listener for FOREGROUND messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');

      // First, perform your tracking logic.


      // Then, show a local OS notification.
      _showLocalNotification(message);
    });

    // 5. Set up the listener for when a user taps a notification from the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');

      // You can also add navigation logic here if the user opens the app via notification.
    });
  }
  // 6. This private method displays the notification.
  static void _showLocalNotification(RemoteMessage message) {
    _localNotificationsPlugin.show(
      message.hashCode, // A unique ID for this specific notification.
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'showbiz_channel_id', // Must match the channel ID from _createNotificationChannel.
          'Showbiz Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification', // The icon to display.
        ),
      ),
      payload: message.data['post_id'], // Example of passing data to the tap handler.
    );
  }

  // 7. This helper method creates the notification channel.
  static void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'showbiz_channel_id', // A unique ID for the channel.
      'Showbiz Notifications', // A user-visible name for the channel.
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Register the channel with the OS.
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  static void showOSNotification(RemoteMessage message) {
    _localNotificationsPlugin.show(
      message.hashCode, // Unique ID for this notification
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // Must match the channel ID from main.dart
          'General', // Must match the channel name
          channelDescription: 'General app notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification', // The icon file in res/drawable
        ),
      ),
      payload: message.data.toString(),
    );
  }
  static void initialize() {
    setup();
    // 1. Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        // If we have a notification, show the banner
        showNotificationBanner(message);
      }
    });

    // 2. Handle messages when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Here you can add logic to navigate the user to a specific page
      // e.g., navigatorKey.currentState?.pushNamed('/post', arguments: message.data['postId']);
    });
  }

  static void showNotificationBanner(RemoteMessage message) {
    // Use the global navigatorKey's context. This is the crucial part.
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Cannot show notification banner, context is null.");
      return;
    }

    Flushbar(
      titleText: Text(
        message.notification?.title ?? "New Notification",
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Colors.white,
            fontFamily: 'Poppins'),
      ),
      messageText: Text(
        message.notification?.body ?? "",
        style: const TextStyle(
            fontSize: 16.0, color: Colors.white, fontFamily: 'Poppins'),
      ),
      duration: const Duration(seconds: 5),
      icon: const Icon(
        Icons.notifications_active,
        color: Colors.white,
        size: 28.0,
      ),
      backgroundGradient: LinearGradient(
        colors: [Colors.orange.shade800, Colors.orange.shade500],
      ),
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      isDismissible: true,
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }
}
