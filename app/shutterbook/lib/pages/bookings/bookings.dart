import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/client_table.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final bookingTable = BookingTable();
  final quoteTable = QuoteTable();
  final clientTable = ClientTable();
  List<Booking> bookings = [];
  List<Client> allClients = [];
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
    _loadBookings();
    _loadClients();
  }

  Future<void> _loadBookings() async {
    final data = await bookingTable.getAllBookings();
    setState(() {
      bookings = data;
    });
  }

  Future<void> _loadClients() async {
    final data = await clientTable.getAllClients();
    setState(() {
      allClients = data;
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
    Client? selectedClient;
    int? selectedQuoteId = existing?.quoteId;
    List<Quote> clientQuotes = [];
    String status = existing?.status ?? '';

    // If editing, preselect client and load quotes
    if (existing != null) {
      if (allClients.isNotEmpty) {
        selectedClient = allClients.firstWhere(
          (c) => c.id == existing.clientId,
          orElse: () => allClients.first,
        );
        // selectedClient guaranteed non-null here because allClients is not empty
  clientQuotes = await quoteTable.getQuotesByClient(selectedClient.id!);
        if (clientQuotes.isNotEmpty &&
            (selectedQuoteId == null ||
                !clientQuotes.any((q) => q.id == selectedQuoteId))) {
          selectedQuoteId = clientQuotes.first.id;
        }
      } else {
        selectedClient = null;
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          List<Client> filteredClients = allClients;
          TextEditingController searchController = TextEditingController();

          void filterClients(String value) {
            setStateDialog(() {
              filteredClients = allClients
                  .where((c) =>
                      c.firstName.toLowerCase().contains(value.toLowerCase()) ||
                      c.lastName.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          }

          return AlertDialog(
            title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar for clients
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Client by Name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filterClients,
                  ),
                  const SizedBox(height: 8),
                  // Dropdown for clients
                  DropdownButtonFormField<Client>(
                    value: selectedClient,
                    items: filteredClients
                        .map((c) => DropdownMenuItem<Client>(
                              value: c,
                              child: Text(
                                  '${c.firstName} ${c.lastName} (${c.email})'),
                            ))
                        .toList(),
                    onChanged: (client) async {
                      if (client == null) return;
            final quotes =
              await quoteTable.getQuotesByClient(client.id!);
                      setStateDialog(() {
                        selectedClient = client;
                        clientQuotes = quotes;
                        selectedQuoteId =
                            clientQuotes.isNotEmpty ? clientQuotes.first.id! : null;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Client'),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 8),
                  // Dropdown for quotes
                  DropdownButtonFormField<int>(
                    value: selectedQuoteId,
                    items: clientQuotes
                        .map((q) => DropdownMenuItem<int>(
                              value: q.id!,
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
                    disabledHint: const Text('Select a client first'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: status),
                    decoration:
                        const InputDecoration(labelText: 'Status (Optional)'),
                    onChanged: (val) => status = val,
                  ),
                ],
              ),
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
                    Navigator.pop(context);
                    _loadBookings();
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () async {
                  if (selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a client.')),
                    );
                    return;
                  }
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
                      clientId: selectedClient!.id!,
                      bookingDate: slot,
                      status: status.isEmpty ? "Scheduled" : status,
                      createdAt: existing.createdAt,
                    );
                    await bookingTable.updateBooking(updated);
                  } else {
                    Booking newBooking = Booking(
                      quoteId: selectedQuoteId!,
                      clientId: selectedClient!.id!,
                      bookingDate: slot,
                      status: status.isEmpty ? "Scheduled" : status,
                    );
                    await bookingTable.insertBooking(newBooking);
                  }

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