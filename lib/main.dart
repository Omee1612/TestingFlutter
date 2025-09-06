import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lagbe_lagbe/home_page.dart';
import 'package:lagbe_lagbe/splash_screen.dart';
import 'firebase_options.dart';
import 'loginlogic.dart';
import 'homePageMain.dart';
import 'loginregscreen.dart'; // your welcome screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lagbo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/mainsc': (context) => const HomePage(),
      },
      home: AnimatedScWidget(),
    );
  }
}
