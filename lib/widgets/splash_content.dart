// splash_content.dart (Updated widget)
import 'package:flutter/material.dart';

class SplashContent extends StatelessWidget {
  final String image;
  final String text;
  final bool isLast;
  final VoidCallback onStart;

  const SplashContent({
    Key? key,
    required this.image,
    required this.text,
    required this.isLast,
    required this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This widget is now replaced by the inline content in SplashIntroScreen
    // but kept for compatibility
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: 300,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 40),
          Text(
            text,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isLast) ...[
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1e3c72),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}