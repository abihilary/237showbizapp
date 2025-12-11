import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showbizapp/DTOs/UserModel.dart';
import 'package:showbizapp/DTOs/post_model.dart';
import 'package:showbizapp/firebase_options.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import 'package:showbizapp/pages/Event.dart';
import 'package:showbizapp/pages/Home.dart';
import 'package:showbizapp/pages/News.dart';
import 'package:showbizapp/services/NotificationService.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// --- BACKGROUND HANDLER ---
// This is the function that runs when a notification arrives and the app is CLOSED.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // CRITICAL FIX: You MUST initialize the service and call the OS notification method.
  // DO NOT call a method that shows a UI banner like Flushbar.
   NotificationService.initialize();
  NotificationService.showOSNotification(message);
}

// --- MAIN FUNCTION ---
// This is the entry point of your app.
void main() async {
  // 1. Ensure Flutter bindings are ready.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase and local database (Hive).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(PostModelAdapter());
  await Hive.openBox<PostModel>('postsBox');

  // 3. Set up the background and foreground message handlers via our centralized service.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   NotificationService.initialize(); // Use await because it's now a Future

  // 4. Run the app.
  runApp(const MyApp());
}

// --- ROOT WIDGET ---
// This widget handles runtime permissions and then shows the main app UI.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This is the single plugin instance needed for local notifications.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // In initState, we call ONE master function to handle all notification setup.
    requestAndPrimeNotifications();
  }

  // This is the primary function for setting up notifications when the app starts.
  Future<void> requestAndPrimeNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Request permission from the user (for Android 13+).
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Only proceed if the user grants permission.
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted notification permission.");

      // 3. Initialize the local notifications plugin and create the channel.
      await _initLocalNotifications();

      // 4. IMPORTANT: Post one local notification to "prime" the app.
      // This makes it visible in the Samsung (OneUI) settings list.
      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        'Notifications Enabled',
        'You will now receive alerts from 237Showbiz.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // This MUST match your channel ID
            'General', // This MUST match your channel name
            importance: Importance.low, // Use low importance to avoid making a sound
            priority: Priority.low,
          ),
        ),
      );

      // 5. Enable FCM auto-initialization and subscribe to the broadcast topic.
      await messaging.setAutoInitEnabled(true);
      await messaging.subscribeToTopic('all');
      print("Subscribed to 'all' topic and enabled auto-init.");

      // 6. Get the device token and register it with your server.
      final token = await messaging.getToken();
      if (token != null) {
        _sendTokenToServer(token);
      }
      messaging.onTokenRefresh.listen(_sendTokenToServer);

    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  // Helper function to initialize the local notifications plugin.
  Future<void> _initLocalNotifications() async {
    // The icon 'ic_notification' must exist in android/app/src/main/res/drawable/
    const initAndroid = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: initAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'General',
      description: 'General app notifications',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print("Notification channel created.");
  }

  // This function sends the device token to your backend.
  Future<void> _sendTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberId = prefs.getString('subscriberId'); // This may be null.

    final url = Uri.parse('https://237showbiz.com/api/subscriber_route.php');

    try {
      print("Sending FCM token to server... Subscriber ID: $subscriberId");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'register_device_token',
          if (subscriberId != null && subscriberId.isNotEmpty)
            'subscriberId': subscriberId,
          'fcmToken': token,
          'deviceType': Platform.isAndroid ? 'android' : 'ios',
        }),
      );
      print('FCM token registration attempt sent to server.');
    } catch (e) {
      print('Error sending FCM token to server: $e');
    }
  }

  // NOTE: All other redundant methods like _configureFirebaseMessaging,
  // _setupFirebaseMessaging, _showNotificationBanner have been REMOVED.
  // Their functionality is now correctly handled here or in NotificationService.dart.

  @override
  Widget build(BuildContext context) {
    // The UI part of your app remains unchanged.
    return ChangeNotifierProvider<UserModel>(
      create: (_) => UserModel(),
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey, // Essential for foreground notifications
        title: '237Showbiz',
        initialRoute: '/home',
        routes: {
          '/home': (context) => Home(),
          '/trending': (context) => Commingsoon(),
          '/news': (context) => NewsPage(),
          '/events': (context) => EventsPage(),
        },
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
      ),
    );
  }
}
