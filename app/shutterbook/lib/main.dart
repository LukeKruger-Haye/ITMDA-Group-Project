import 'package:flutter/material.dart';
import 'inventory.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Shutterbook',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: MyHomePage(),
        );
    }
}

class MyHomePage extends StatefulWidget {
    @override
    _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    int _currentIndex = 0;

    final List<Widget> _tabs = [
        HomeScreen(),
        BookingsScreen(),
        ManageScreen(),
    ];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Shutterbook'),
            ),
            body: _tabs[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (int index) {
                    setState(() {
                        _currentIndex = index;
                    });
                },
                items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Bookings',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Manage',
                    ),
                ],
            ),
        );
    }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InventoryPage()),
          );
        },
        icon: const Icon(Icons.inventory),
        label: const Text('Go to Inventory'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class BookingsScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text('Bookings Screen'),
        );
    }
}

class ManageScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text('Manage Screen'),
        );
    }
}
