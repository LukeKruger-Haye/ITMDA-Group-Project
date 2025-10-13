import 'package:flutter/material.dart';
import '/Models/auth_model.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthModel authModel;

  const HomeScreen({super.key, required this.authModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(authModel: authModel),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Welcome Home!')),
    );
  }
}
