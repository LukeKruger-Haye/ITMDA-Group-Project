import 'package:flutter/material.dart';
import 'package:shutterbook/pages/quotes/manage/manage_quote.dart';

class ManageQuotePage extends StatelessWidget {
  const ManageQuotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quotes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ManageQuote()
          ),
        ),
      );
    
  }
}
