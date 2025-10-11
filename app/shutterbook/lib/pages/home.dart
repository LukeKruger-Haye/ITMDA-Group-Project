import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShutterBook Dashboard')),
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
            onTap: () => Navigator.pushNamed(context, '/quotes'),
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
