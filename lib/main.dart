import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home.dart';

import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static String appName = "Calories Counter";

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> fApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MyApp.appName,
      theme: ThemeData(primarySwatch: Colors.pink, fontFamily: 'Montserrat'),
      home: FutureBuilder(
          future: fApp,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Something went wrong with firebase.");
            } else if (snapshot.hasData) {
              return const HomePage();
            }
            return const CircularProgressIndicator();
          }),
      debugShowCheckedModeBanner: false,
    );
  }
}
