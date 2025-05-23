import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  late String mobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mobile = ModalRoute.of(context)!.settings.arguments as String;
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final response = await http.get(
      Uri.parse("http://localhost:3000/user?mobile=$mobile"),
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Profile")),
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Full Name: ${userData['fullName']}"),
                  Text("DOB: ${userData['dob']}"),
                  Text("Gender: ${userData['gender']}"),
                  Text("Address: ${userData['address']}"),
                  Text("Mobile: ${userData['mobile']}"),
                ],
              ),
            ),
    );
  }
}
