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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Sign up to get started",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Full Name
                    buildInputField(
                      label: "Full Name",
                      onChanged: (val) => formData["fullName"] = val,
                    ),

                    // Date of Birth
                    buildInputField(
                      label: "Date of Birth",
                      onChanged: (val) => formData["dob"] = val,
                    ),

                    // Gender
                    DropdownButtonFormField<String>(
                      value: formData["gender"],
                      dropdownColor: Color(0xFF1e3c72),
                      decoration: inputDecoration("Gender"),
                      items: ['Male', 'Female', 'Binary', 'Others']
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => formData["gender"] = val!);
                      },
                    ),
                    SizedBox(height: 16),

                    // Address
                    buildInputField(
                      label: "Address",
                      onChanged: (val) => formData["address"] = val,
                    ),

                    // Mobile Number
                    buildInputField(
                      label: "Mobile Number",
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => formData["mobile"] = val,
                    ),

                    // Password
                    buildInputField(
                      label: "Password",
                      obscureText: true,
                      onChanged: (val) => formData["password"] = val,
                    ),

                    SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF1e3c72),
                        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),

                    SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: inputDecoration(label),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
