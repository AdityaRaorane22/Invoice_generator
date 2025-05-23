import 'package:flutter/material.dart';

class SplashContent extends StatelessWidget {
  final String text, image;
  final bool isLast;
  final VoidCallback onStart;

  const SplashContent({
    required this.text,
    required this.image,
    required this.isLast,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 300),
        SizedBox(height: 20),
        Text(text, style: TextStyle(fontSize: 20)),
        if (isLast) ...[
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: onStart,
            child: Text("Let's Start"),
          ),
        ]
      ],
    );
  }
}
