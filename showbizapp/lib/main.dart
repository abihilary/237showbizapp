import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import 'package:showbizapp/pages/Event.dart';
import 'package:showbizapp/pages/Home.dart';
import 'package:showbizapp/pages/News.dart';
import 'package:showbizapp/DTOs/UserModel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:showbizapp/DTOs/post_model.dart';
import 'firebase_options.dart';

// --- ADD THIS FUNCTION ---
// This handler must be a top-level function (outside of any class)
// It handles messages that arrive when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You must initialize Firebase in the background handler as well.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- ADD FIREBASE MESSAGING SETUP ---

  // 1. Set the background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Request notification permissions from the user
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 3. Subscribe to the 'all' topic if permission is granted
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permission');
    await messaging.subscribeToTopic('all');
    print("Device subscribed to 'all' topic");
  } else {
    print('User declined or has not accepted notification permission');
  }

  // --- END FIREBASE MESSAGING SETUP ---

  // Hive initialization (your existing code is correct)
  await Hive.initFlutter();
  Hive.registerAdapter(PostModelAdapter());
  await Hive.openBox<PostModel>('postsBox');

  runApp(
    ChangeNotifierProvider<UserModel>(
      create: (_) => UserModel(),
      child: MaterialApp(
        // Your existing MaterialApp is correct
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
    ),
  );
}