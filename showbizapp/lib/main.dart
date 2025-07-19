import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import 'package:showbizapp/pages/Event.dart';
import 'package:showbizapp/pages/Home.dart';
import 'package:showbizapp/pages/MusicVideoPage.dart';
import 'package:showbizapp/pages/News.dart';
import 'package:showbizapp/DTOs/UserModel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:showbizapp/DTOs/post_model.dart'; // Your Hive model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization
  await Hive.initFlutter();
  Hive.registerAdapter(PostModelAdapter()); // Register your adapter

  await Hive.openBox<PostModel>('postsBox'); // Open your box

  runApp(
    ChangeNotifierProvider<UserModel>(
      create: (_) => UserModel(),
      child: MaterialApp(
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
          Locale('en', ''), // English
        ],
      ),
    ),
  );
}
