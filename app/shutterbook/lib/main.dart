import 'package:flutter/material.dart';
import 'package:shutterbook/dashboard.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Shutterbook',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: const MyHomePage(),
        );
    }
}

class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key});

    @override
    State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
    int _currentIndex = 0;

    final List<Widget> _tabs = const [
        DashboardPage(),
        BookingsScreen(),
        ManageScreen(),
    ];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Shutterbook'),
            ),
            body: _tabs[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (int index) {
                    setState(() {
                        _currentIndex = index;
                    });
                },
                items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard),
                        label: 'Dashboard',
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

class BookingsScreen extends StatelessWidget {
    const BookingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return const Center(
            child: Text('Bookings Screen'),
        );
    }
}

class ManageScreen extends StatelessWidget {
    const ManageScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return const Center(
            child: Text('Manage Screen'),
        );
    }
}
