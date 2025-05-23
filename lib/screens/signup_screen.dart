import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> formData = {
    "fullName": "",
    "dob": "",
    "gender": "Male",
    "address": "",
    "mobile": "",
    "password": ""
  };

  Future<void> registerUser() async {
    final response = await http.post(
      Uri.parse("http://localhost:3000/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Success"),
          content: Text("Registered successfully!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(decoration: InputDecoration(labelText: 'Full Name'), onChanged: (val) => formData["fullName"] = val),
              TextFormField(decoration: InputDecoration(labelText: 'Date of Birth'), onChanged: (val) => formData["dob"] = val),
              DropdownButtonFormField(
                value: formData["gender"],
                items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => formData["gender"] = val as String),
              ),
              TextFormField(decoration: InputDecoration(labelText: 'Address'), onChanged: (val) => formData["address"] = val),
              TextFormField(decoration: InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone, onChanged: (val) => formData["mobile"] = val),
              TextFormField(decoration: InputDecoration(labelText: 'Password'), obscureText: true, onChanged: (val) => formData["password"] = val),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Sign Up"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) registerUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
