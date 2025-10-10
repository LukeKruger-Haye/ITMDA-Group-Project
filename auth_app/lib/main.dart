import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Pages/login_screen.dart';
import 'Pages/setup_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> hasPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('app_password');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: FutureBuilder<bool>(
        future: hasPasswordSet(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return snapshot.data! ? const LoginScreen() : const SetupScreen();
        },
      ),
    );
  }
}
