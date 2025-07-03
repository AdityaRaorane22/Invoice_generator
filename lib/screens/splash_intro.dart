// splash_intro_screen.dart
import 'package:flutter/material.dart';

class SplashIntroScreen extends StatefulWidget {
  @override
  _SplashIntroScreenState createState() => _SplashIntroScreenState();
}

class _SplashIntroScreenState extends State<SplashIntroScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> splashData = [
    {
      "title": "Smart AI Assistant",
      "description": "Get instant answers about inventory status, product details, and company information with our intelligent AI chat.",
      "icon": Icons.smart_toy,
      "color": Color(0xFF3b82f6),
    },
    {
      "title": "Invoice Generation",
      "description": "Create professional invoices with automatic numbering and proper tracking for different companies.",
      "icon": Icons.receipt_long,
      "color": Color(0xFF2563eb),
    },
    {
      "title": "Sales Tracking",
      "description": "Monitor sales performance and track warranty status before and after purchase with detailed analytics.",
      "icon": Icons.analytics,
      "color": Color(0xFF1d4ed8),
    },
    {
      "title": "Get Started",
      "description": "Join thousands of sales professionals who trust SmartInvoice for their business needs.",
      "icon": Icons.rocket_launch,
      "color": Color(0xFF1e40af),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentIndex < splashData.length - 1)
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Page content
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: splashData.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final data = splashData[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              data['icon'],
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 40),
                          
                          // Title
                          Text(
                            data['title'],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          
                          // Description
                          Text(
                            data['description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        splashData.length,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Navigation buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous button
                          if (_currentIndex > 0)
                            TextButton(
                              onPressed: () {
                                _controller.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                                  Text(
                                    'Previous',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(width: 80),
                          
                          // Next/Get Started button
                          ElevatedButton(
                            onPressed: () {
                              if (_currentIndex == splashData.length - 1) {
                                Navigator.pushReplacementNamed(context, '/login');
                              } else {
                                _controller.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF1e3c72),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentIndex == splashData.length - 1 
                                      ? 'Get Started' 
                                      : 'Next',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  _currentIndex == splashData.length - 1 
                                      ? Icons.rocket_launch 
                                      : Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}