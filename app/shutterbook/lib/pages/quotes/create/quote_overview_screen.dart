import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/pages/quotes/create/package_picker.dart';

class QuoteOverviewScreen extends StatelessWidget {
final String total;
final Client client;
final Map<Package, int> packages;


  const QuoteOverviewScreen({super.key, required this.client, required this.total, required this.packages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Overview')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Client: ${client.firstName} ${client.lastName}'),
            Text('Total: R$total'),
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map((entry) => Text('${entry.key.name} x${entry.value} - R${(entry.key.price * entry.value).toStringAsFixed(2)}')),
           
          ],
        ),
      ),
    );
  }
}