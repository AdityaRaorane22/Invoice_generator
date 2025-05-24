import 'package:flutter/material.dart';
import 'package:invoice/screens/chat_screen.dart';
import 'package:invoice/screens/generate_invoice.dart';

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
        GenerateInvoiceScreen(),
        Center(
          child: Text(
            'Profile',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        Center(
          child: Text(
            'About App',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        Container(), // logout navigation
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
      appBar: AppBar(
        title: Text("Welcome"),
        backgroundColor: Color(0xFF1e3c72),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _selectedIndex == 2 || _selectedIndex == 4
            ? Container() // no screen for profile/logout, handled with nav
            : _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Color(0xFF1e3c72),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoice'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
