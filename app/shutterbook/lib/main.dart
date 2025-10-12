import 'package:flutter/material.dart';
import 'package:shutterbook/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shutterbook/pages/authentication/setup.dart';
import 'package:shutterbook/pages/authentication/login.dart';

import 'package:shutterbook/pages/bookings/bookings.dart';

import 'package:shutterbook/pages/quotes/quote_screen.dart';
import 'package:shutterbook/pages/quotes/create_quote.dart';
import 'package:shutterbook/pages/quotes/manage_quote.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShutterBookApp());
}

class ShutterBookApp extends StatefulWidget {
  const ShutterBookApp({super.key});

  @override
  State<ShutterBookApp> createState() => _ShutterBookAppState();
}

class _ShutterBookAppState extends State<ShutterBookApp> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('app_password');

    setState(() {
      if (savedPassword == null || savedPassword.isEmpty) {
        _startScreen = const SetupScreen();
      } else {
        _startScreen = const LoginScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_startScreen == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'ShutterBook',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: _startScreen,
      routes: {
        '/home': (context) => const HomePage(),
        '/bookings': (context) => const BookingsPage(),
        '/quotes/quote_screen.dart':(context) => const QuotePage(),
        '/quotes/create_quote.dart':(context) => const CreateQuotePage(),
        '/quotes/manage_quote.dart':(context) => const ManageQuotePage(),
      },
    );
  }
}
