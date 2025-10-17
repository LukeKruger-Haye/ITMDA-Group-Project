import 'package:flutter/material.dart';
import 'authentication/models/auth_model.dart';
import 'settings/settings.dart';

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
      body: ListView(
        children: [
          ListTile(
            title: const Text('Clients'),
            subtitle: const Text('Manage clients and their details'),
            trailing: const Icon(Icons.people),
            onTap: () => Navigator.pushNamed(context, '/clients'),
          ),
          ListTile(
            title: const Text('Quotes'),
            subtitle: const Text('Create and view quotes'),
            trailing: const Icon(Icons.request_quote),
            onTap: () => Navigator.pushNamed(context, '/quotes/manage/manage_quote_screen.dart'),
          ),
          ListTile(
            title: const Text('Bookings'),
            subtitle: const Text('Track scheduled sessions'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => Navigator.pushNamed(context, '/bookings'),
          ),
        ],
      ),
    );
  }
}
