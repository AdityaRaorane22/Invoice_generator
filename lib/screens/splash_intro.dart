import 'package:flutter/material.dart';
import '../widgets/splash_content.dart';

class SplashIntroScreen extends StatefulWidget {
  @override
  _SplashIntroScreenState createState() => _SplashIntroScreenState();
}

class _SplashIntroScreenState extends State<SplashIntroScreen> {
  final PageController _controller = PageController();

  // ignore: unused_field
  int _currentIndex = 0;

  final List<Map<String, String>> splashData = [
    {"text": "s1", "image": "assets/s1.png"},
    {"text": "s2", "image": "assets/s2.png"},
    {"text": "s3", "image": "assets/s3.png"},
    {"text": "s4", "image": "assets/s4.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: splashData.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) => SplashContent(
          image: splashData[index]['image']!,
          text: splashData[index]['text']!,
          isLast: index == splashData.length - 1,
          onStart: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
    );
  }
}
