import 'package:flutter/material.dart';

class QuoteOverviewScreen extends StatelessWidget {
final String client, total;
final List packages;


  const QuoteOverviewScreen({super.key, required this.client, required this.total, required this.packages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Overview')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Client: $client'),
            Text('Total: R$total'),
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
           
          ],
        ),
      ),
    );
  }
}