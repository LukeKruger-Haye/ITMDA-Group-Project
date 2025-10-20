import 'package:flutter/material.dart';
import 'data/models/booking.dart';
import 'data/models/quote.dart';
import 'data/tables/booking_table.dart';
import 'data/tables/quote_table.dart';
import 'pages/bookings/create_booking.dart';

enum BookingFilter { all, upcoming }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Filter: all vs upcoming
  BookingFilter _filter = BookingFilter.upcoming;

  Future<void> _openCreateBooking(BuildContext context, Quote quote) async {
    // Close dialog first
    Navigator.of(context).pop();
    // Navigate to create booking page and wait for result
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingPage(quote: quote),
      ),
    );
    if (created == true && mounted) {
      setState(() {}); // trigger refresh of bookings list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photography Bookings Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(builder: (context) {
                  // Compact, wrap-friendly controls for small screens
                  final ButtonStyle style = ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14),
                  );
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        style: style,
                        onPressed: () => _showQuotesDialog(context),
                        child: const Text('Quotes'),
                      ),
                      DropdownButtonHideUnderline(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: DropdownButton<BookingFilter>(
                              isDense: true,
                              value: _filter,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black87),
                              iconEnabledColor: Colors.black54,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _filter = value);
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: BookingFilter.upcoming,
                                  child: Text('Upcoming only'),
                                ),
                                DropdownMenuItem(
                                  value: BookingFilter.all,
                                  child: Text('All bookings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            // Responsive list/grid of bookings
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<Booking>>(
                  future: BookingTable().getAllBookings(),
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
                    var bookings = snapshot.data ?? const <Booking>[];
                    if (_filter == BookingFilter.upcoming) {
                      final now = DateTime.now();
                      bookings = bookings.where((b) => b.bookingDate.isAfter(now)).toList();
                      bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
                    }
                    if (bookings.isEmpty) {
                      return const Center(child: Text('No bookings found.'));
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        Widget buildCard(Booking b) {
                          final title = 'Booking #${b.bookingId}';
                          final subtitle = 'Status: ${b.status}';
                          final details = 'Date: ${b.bookingDate}';
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt, size: 36, color: Colors.deepPurple),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    details,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final isPhone = constraints.maxWidth < 480;
                        if (isPhone) {
                          return ListView.separated(
                            itemCount: bookings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => buildCard(bookings[index]),
                          );
                        }

                        final crossAxisCount = (constraints.maxWidth / 360).floor().clamp(2, 6);
                        return GridView.builder(
                          itemCount: bookings.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) => buildCard(bookings[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
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
                    final subtitle = 'Total: ${q.totalPrice} • ${q.createdAt}';
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(title),
                      subtitle: Text(
                        '${q.description}\n$subtitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _openCreateBooking(ctx, q),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Book'),
                      ),
                      onTap: () => _openCreateBooking(ctx, q),
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
