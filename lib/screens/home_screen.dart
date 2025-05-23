import 'package:flutter/material.dart';
import 'package:invoice/screens/chat_screen.dart';
import 'package:invoice/screens/generate_invoice.dart';  // import your invoice screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late String mobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mobile = ModalRoute.of(context)!.settings.arguments as String;
  }

  List<Widget> get _pages => <Widget>[
        ChatScreen(mobile: mobile),
        GenerateInvoiceScreen(),  // use your actual invoice screen here
        Center(child: Text('Profile')), // Placeholder text, you can replace with Profile screen
        Center(child: Text('About App')),
        Center(child: Text('Logging Out...')),
      ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/profile', arguments: mobile);
    } else if (index == 4) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: _selectedIndex == 2 || _selectedIndex == 4
          ? Container() // no body shown for profile and logout handled by navigation
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoice'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
