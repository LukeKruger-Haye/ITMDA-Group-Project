import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final bookingTable = BookingTable();
  final quoteTable = QuoteTable();
  List<Booking> bookings = [];
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final data = await bookingTable.getAllBookings();
    setState(() {
      bookings = data;
    });
  }

  Booking? getBookingForSlot(DateTime slot) {
    try {
      return bookings.firstWhere(
        (b) =>
            b.bookingDate.year == slot.year &&
            b.bookingDate.month == slot.month &&
            b.bookingDate.day == slot.day &&
            b.bookingDate.hour == slot.hour,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _editBooking(DateTime slot, [Booking? existing]) async {
    final customerController =
        TextEditingController(text: existing?.clientId.toString() ?? '');
    final statusController =
        TextEditingController(text: existing?.status ?? '');

    int? selectedQuoteId = existing?.quoteId;
    List<Quote> clientQuotes = [];

    // If editing, load quotes for the existing client
    if (existing != null) {
      clientQuotes = await quoteTable.getQuotesByClient(existing.clientId);
      if (clientQuotes.isNotEmpty &&
          (selectedQuoteId == null ||
              !clientQuotes.any((q) => q.clientId == selectedQuoteId))) {
        selectedQuoteId = clientQuotes.first.clientId;
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> onClientChanged(String value) async {
            int clientId = int.tryParse(value.trim()) ?? 0;
            if (clientId > 0) {
              final quotes = await quoteTable.getQuotesByClient(clientId);
              setStateDialog(() {
                clientQuotes = quotes;
                selectedQuoteId =
                    clientQuotes.isNotEmpty ? clientQuotes.first.clientId : null;
              });
            } else {
              setStateDialog(() {
                clientQuotes = [];
                selectedQuoteId = null;
              });
            }
          }

          return AlertDialog(
            title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: customerController,
                  decoration: const InputDecoration(labelText: 'Client ID'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    onClientChanged(value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: selectedQuoteId,
                  items: clientQuotes
                      .map((q) => DropdownMenuItem<int>(
                            value: q.clientId,
                            child: Text(q.description),
                          ))
                      .toList(),
                  onChanged: clientQuotes.isEmpty
                      ? null
                      : (val) {
                          setStateDialog(() {
                            selectedQuoteId = val;
                          });
                        },
                  decoration: const InputDecoration(labelText: 'Quote'),
                  hint: const Text('Select Quote'),
                  isExpanded: true,
                  disabledHint: const Text('Enter Client ID first'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: statusController,
                  decoration:
                      const InputDecoration(labelText: 'Status (Optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              if (existing != null)
                TextButton(
                  onPressed: () async {
                    await bookingTable.deleteBooking(existing.bookingId!);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadBookings();
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () async {
                  int clientId =
                      int.tryParse(customerController.text.trim()) ?? 1;
                  String status = statusController.text.trim().isEmpty
                      ? "Scheduled"
                      : statusController.text.trim();

                  if (selectedQuoteId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please select a quote for this client.')),
                    );
                    return;
                  }

                  if (existing != null) {
                    Booking updated = Booking(
                      bookingId: existing.bookingId,
                      quoteId: selectedQuoteId!,
                      clientId: clientId,
                      bookingDate: slot,
                      status: status,
                      createdAt: existing.createdAt,
                    );
                    await bookingTable.updateBooking(updated);
                  } else {
                    Booking newBooking = Booking(
                      quoteId: selectedQuoteId!,
                      clientId: clientId,
                      bookingDate: slot,
                      status: status,
                    );
                    await bookingTable.insertBooking(newBooking);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadBookings();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _previousWeek() {
    setState(() {
      weekStart = weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      weekStart = weekStart.add(const Duration(days: 7));
    });
  }

  String getWeekdayName(DateTime date) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(10, (i) => 8 + i);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    
    const double timeColumnWidth = 60;
    const double blockColumnWidth = 44; 
    const double whiteSpaceWidth = 40; 

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Calendar')),
      body: Column(
        children: [
          // Date row with arrows
          Row(
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousWeek,
                  tooltip: 'Previous Week',
                ),
              ),
              for (int i = 0; i < days.length; i++)
                SizedBox(
                  width: blockColumnWidth,
                  child: Center(
                    child: Text(
                      "${days[i].day.toString().padLeft(2, '0')}/${days[i].month.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              SizedBox(
                width: whiteSpaceWidth,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextWeek,
                  tooltip: 'Next Week',
                ),
              ),
            ],
          ),
          // Days row
          Row(
            children: [
              SizedBox(width: timeColumnWidth),
              for (final d in days)
                SizedBox(
                  width: blockColumnWidth,
                  child: Center(
                    child: Text(
                      getWeekdayName(d),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              SizedBox(width: whiteSpaceWidth),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: hours.length,
              itemBuilder: (_, row) {
                final hour = hours[row];
                return Row(
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      child: Text(
                        "$hour:00",
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    for (final d in days)
                      SizedBox(
                        width: blockColumnWidth,
                        child: GestureDetector(
                          onTap: () {
                            final slot = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              hour,
                            );
                            final booking = getBookingForSlot(slot);
                            _editBooking(slot, booking);
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            height: 50,
                            decoration: BoxDecoration(
                              color: (() {
                                final slot = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  hour,
                                );
                                final booking = getBookingForSlot(slot);
                                if (booking != null) {
                                  return Colors.green[300];
                                }
                                return Colors.grey[200];
                              })(),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Builder(
                              builder: (context) {
                                final slot = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  hour,
                                );
                                final booking = getBookingForSlot(slot);
                                if (booking != null) {
                                  return Center(
                                    child: Text(
                                      "Client: ${booking.clientId}\nQuote: ${booking.quoteId}\n${booking.status}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
                    // White space column at the end
                    SizedBox(width: whiteSpaceWidth),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
