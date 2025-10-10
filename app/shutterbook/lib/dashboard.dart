import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'models/booking.dart';
import 'models/quote.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photography Bookings Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: 'View Quotes',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _showQuotesDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Booking>>(
          future: DatabaseHelper.instance.getAllBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load bookings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            final bookings = snapshot.data ?? const <Booking>[];
            if (bookings.isEmpty) {
              return const Center(child: Text('No bookings found.'));
            }

            return GridView.builder(
              itemCount: bookings.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final b = bookings[index];
                final title = 'Booking #${b.bookingId}';
                final subtitle = 'Status: ${b.status}';
                final details = 'Date: ${b.bookingDate}';

                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showQuotesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('All Quotes'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: FutureBuilder<List<Quote>>(
              future: DatabaseHelper.instance.getAllQuotes(),
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
                    final subtitle =
                        'Total: ${q.totalPrice} • ${q.createdAt}';
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(title),
                      subtitle: Text(
                        '${q.description}\n$subtitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
