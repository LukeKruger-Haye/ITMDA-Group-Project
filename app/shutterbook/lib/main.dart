import 'package:flutter/material.dart';
import 'package:shutterbook/pages/home.dart';

import 'package:shutterbook/pages/bookings/bookings.dart';

void main() {
  runApp(const ShutterBookApp());
}

class ShutterBookApp extends StatelessWidget {
  const ShutterBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShutterBook',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        // '/clients': (context) => const ClientsPage(),
        '/bookings': (context) => const BookingsPage(),
        // '/quotes': (context) => const QuotesPage(),
      },
    );
  }
}
