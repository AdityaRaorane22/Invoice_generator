import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _loginUser() async {
    final mobile = phoneController.text.trim();
    final password = passwordController.text.trim();

    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'password': password}),
    );

    final result = jsonDecode(response.body);

    if (result["success"] == true) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: mobile,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Mobile No'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _loginUser, child: Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text("Haven't signed up yet?"),
            ),
          ],
        ),
      ),
    );
  }
}
