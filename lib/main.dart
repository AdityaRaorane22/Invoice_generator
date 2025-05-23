import 'package:flutter/material.dart';
import 'package:invoice/screens/home_screen.dart';
import 'package:invoice/screens/profile_page.dart';
import 'package:invoice/screens/signup_screen.dart';
import 'screens/splash_logo.dart';
import 'screens/splash_intro.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
      '/': (_) => SplashLogoScreen(),
      '/intro': (_) => SplashIntroScreen(),
      '/login': (_) => LoginScreen(),
      '/signup': (_) => SignupScreen(),
      '/home': (_) => HomeScreen(),
      '/profile': (context) => ProfileScreen(),

    },
  ));
}
