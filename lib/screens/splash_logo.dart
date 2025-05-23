import 'package:flutter/material.dart';
import 'dart:async';

class SplashLogoScreen extends StatefulWidget {
  @override
  _SplashLogoScreenState createState() => _SplashLogoScreenState();
}

class _SplashLogoScreenState extends State<SplashLogoScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: Duration(seconds: 2), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward().then((_) async {
      await Future.delayed(Duration(seconds: 1));
      _controller.reverse().then((_) {
        Navigator.pushReplacementNamed(context, '/intro');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/logo.png', width: 150),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
