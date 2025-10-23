import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/pages/bookings/create_booking.dart';
import 'package:shutterbook/utils/formatters.dart';

class ManageQuotePage extends StatefulWidget {
  const ManageQuotePage({super.key});

  @override
  State<ManageQuotePage> createState() => _ManageQuotePageState();
}

class _ManageQuotePageState extends State<ManageQuotePage> {
  Quote? _quote;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Quote) {
      _load(args);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load(Quote q) async {
    // reload from DB to ensure latest
    final fresh = await QuoteTable().getQuoteById(q.id!);
    if (!mounted) return;
    setState(() {
      _quote = fresh ?? q;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    if (_quote?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text('Are you sure you want to delete this quote?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await QuoteTable().deleteQuotes(_quote!.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_quote == null) return const Scaffold(body: Center(child: Text('Quote not found')));

    return Scaffold(
      appBar: AppBar(title: Text('Quote #${_quote!.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client ID: ${_quote!.clientId}'),
            const SizedBox(height: 8),
            Text('Total: ${formatRand(_quote!.totalPrice)}'),
            const SizedBox(height: 8),
            Text('Description: ${_quote!.description}'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                        // Book from this quote
                        final nav = Navigator.of(context);
                        final created = await nav.push<bool>(
                          MaterialPageRoute(builder: (_) => CreateBookingPage(quote: _quote)),
                        );
                        if (created == true) {
                          if (mounted) nav.pop(true);
                        }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Book'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(onPressed: (){
          Navigator.pushNamed(context, '/quotes/create/create_quote.dart');
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
        ),
      );
    
  }
}
