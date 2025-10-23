import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/utils/formatters.dart';

class QuotesDialog extends StatelessWidget {
  const QuotesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All Quotes'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: FutureBuilder<List<Quote>>(
          future: QuoteTable().getAllQuotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load quotes.'));
            }
            final quotes = snapshot.data ?? const <Quote>[];
            if (quotes.isEmpty) {
              return const Center(child: Text('No quotes found.'));
            }
            return ListView.separated(
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final q = quotes[index];
                final title = 'Quote #${q.id}';
                final subtitle = 'Total: ${formatRand(q.totalPrice)} • ${q.createdAt}';
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(title),
                  subtitle: Text(
                    '${q.description}\n$subtitle',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop<Quote>(q),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Book'),
                  ),
                  onTap: () => Navigator.of(context).pop<Quote>(q),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
