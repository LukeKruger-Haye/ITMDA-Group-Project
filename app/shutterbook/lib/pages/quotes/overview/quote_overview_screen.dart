import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/utils/formatters.dart';

class QuoteOverviewScreen extends StatelessWidget {
final double total;
final Client client;
final Map<Package, int> packages;

  const QuoteOverviewScreen({
    super.key,
    required this.client,
    required this.total,
    required this.packages,
  });

  Future<void> _insertQuote() async {
    final String packageDescription = packages.entries
        .map((entry) => '${entry.key.name} x${entry.value}')
        .join(', ');
    final table = QuoteTable();
    final quote = Quote(
      clientId: client.id!,
      totalPrice: total,
      description: packageDescription,
    );

    await table.insertQuote(quote);
    if (kDebugMode) debugPrint('Inserted quote:${quote.toMap()}');
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('QuoteOverviewScreen built for client ${client.id} total $total');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Overview')),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Client: ${client.id} ${client.firstName} ${client.lastName}'),
            Text('Total: ${formatRand(total)}'),
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map(
              (entry) => Text(
                '${entry.key.name} x${entry.value} - ${formatRand(entry.key.price * entry.value)}',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _insertQuote();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quote saved successfully')),
                    );
                    Navigator.of(context).pop(true); // Pop with true to indicate success
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save quote: $e')),
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}