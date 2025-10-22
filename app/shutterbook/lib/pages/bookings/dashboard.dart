import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/pages/bookings/create_booking.dart';
import 'package:shutterbook/pages/bookings/quotes_dialog.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/pages/bookings/booking_calendar_view.dart';

enum BookingFilter { all, upcoming }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  BookingFilter _filter = BookingFilter.upcoming;
  bool _showCalendar = false;
  // If a client was passed via route arguments, this will be set and the
  // dashboard will show client-scoped lists when requested.
  Client? _clientFromArgs;
  bool _showQuotesInMain = false;
  bool _quotesLoading = false;
  List<Quote> _clientQuotes = [];
  bool _argsProcessed = false;

  Future<void> _openCreateBooking(BuildContext context, Quote quote) async {
    Navigator.of(context).pop();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingPage(quote: quote),
      ),
    );
    if (created == true && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsProcessed) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final maybeClient = args['client'];
      final view = args['view'];
      if (maybeClient is Client) {
        _clientFromArgs = maybeClient;
        // If the client asked to view quotes/bookings, force list mode and
        // show the appropriate view.
        if (view == 'quotes') {
          _showQuotesInMain = true;
          _loadClientQuotes();
        } else if (view == 'bookings') {
          _showCalendar = false;
        }
      }
    }
    _argsProcessed = true;
  }

  Future<void> _loadClientQuotes() async {
    if (_clientFromArgs == null || _clientFromArgs!.id == null) return;
    setState(() {
      _quotesLoading = true;
    });
    final quotes = await QuoteTable().getQuotesByClient(_clientFromArgs!.id!);
    if (!mounted) return;
    setState(() {
      _clientQuotes = quotes;
      _quotesLoading = false;
    });
  }

  Widget _buildQuotesList() {
    if (_quotesLoading) return const Center(child: CircularProgressIndicator());
    if (_clientQuotes.isEmpty) return const Center(child: Text('No quotes for this client'));
    return ListView.separated(
      itemCount: _clientQuotes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final q = _clientQuotes[index];
        final title = 'Quote #${q.id}';
        final subtitle = 'Total: ${q.totalPrice} • ${q.createdAt ?? ''}';
        return ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(title),
          subtitle: Text(
            '${q.description}\n$subtitle',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton.icon(
            onPressed: () async {
              await _openCreateBooking(context, q);
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Book'),
          ),
          onTap: () async {
            await _openCreateBooking(context, q);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _clientFromArgs != null
            ? Text(
                '${_showQuotesInMain ? 'Quotes' : 'Bookings'} — ${_clientFromArgs!.firstName} ${_clientFromArgs!.lastName}',
              )
            : const Text('Photography Bookings Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_clientFromArgs != null)
            IconButton(
              tooltip: 'Clear client filter',
              onPressed: () {
                setState(() {
                  _clientFromArgs = null;
                  _showQuotesInMain = false;
                  _argsProcessed = false;
                });
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(builder: (context) {
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
                        onPressed: () {
                          // If a client is selected (route arg), show the client's
                          // quotes in the dashboard main area. Otherwise fall back
                          // to the global quotes dialog.
                          if (_clientFromArgs != null) {
                            setState(() {
                              _showQuotesInMain = true;
                            });
                            _loadClientQuotes();
                          } else {
                            _showQuotesDialog(context);
                          }
                        },
                        child: const Text('Quotes'),
                      ),
                      // Toggle buttons for List vs Calendar
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('List'),
                            icon: Icon(Icons.view_list),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Calendar'),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: <bool>{_showCalendar},
                        onSelectionChanged: (s) {
                          setState(() => _showCalendar = s.first);
                        },
                      ),
                      if (!_showCalendar)
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _showCalendar
                    ? const BookingCalendarView()
                    : _showQuotesInMain
                        ? _buildQuotesList()
                        : FutureBuilder<List<Booking>>(
                      future: _clientFromArgs != null && _clientFromArgs!.id != null
                          ? BookingTable().getBookingsByClient(_clientFromArgs!.id!)
                          : BookingTable().getAllBookings(),
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
                            itemBuilder: (context, index) {
                              final b = bookings[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateBookingPage(existing: b),
                                    ),
                                  ).then((value) {
                                    if (mounted) setState(() {});
                                  });
                                },
                                child: buildCard(b),
                              );
                            },
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
                          itemBuilder: (context, index) {
                            final b = bookings[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateBookingPage(existing: b),
                                  ),
                                ).then((value) {
                                  if (mounted) setState(() {});
                                });
                              },
                              child: buildCard(b),
                            );
                          },
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

  Future<void> _showQuotesDialog(BuildContext context) async {
    final selectedQuote = await showDialog(
      context: context,
      builder: (context) => const QuotesDialog(),
    );
    if (selectedQuote != null) {
      await _openCreateBooking(context, selectedQuote);
    }
  }
}
