import 'package:flutter/material.dart';

class CreateQuotePage extends StatelessWidget {
  const CreateQuotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quote'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please search client'),
            SizedBox(height: 20),
            SearchBar(
              hintText: 'Search Client',
              onTap: null,

            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: null, // Implement search functionality
              child: Text('Confirm Client'),
            ),
          ],
        ),
      ),
    );
  }
}