import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key});

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
  const HomeScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text('Home Screen'),
        );
    }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text('Bookings Screen'),
        );
    }
}

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Text('Manage Screen'),
        );
    }
}
