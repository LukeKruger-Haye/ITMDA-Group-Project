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
        child: Text('Create a new quote here'),
      ),
    );
  }
}