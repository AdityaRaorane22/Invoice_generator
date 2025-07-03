import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:invoice/screens/splash_logo.dart';
import 'package:invoice/screens/splash_intro.dart';
import 'package:invoice/screens/login_screen.dart';
import 'package:invoice/screens/signup_screen.dart';
import 'package:invoice/screens/home_screen.dart';
import 'package:invoice/screens/profile_page.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
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

    // Now you can write test expectations based on SplashLogoScreen contents,
    // for example check a widget or text that should be visible on splash screen.

    expect(find.byType(SplashLogoScreen), findsOneWidget);
  });
}
