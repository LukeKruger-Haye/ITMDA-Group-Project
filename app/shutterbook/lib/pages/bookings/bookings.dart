import 'dart:async';
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
  Map<String, Client> clientByEmail = {};
  Map<int, Client> clientById = {};
  Map<int, Quote> quoteById = {};
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
    // Load clients first so clientById is available when bookings are displayed
    _loadClients().then((_) => _loadBookings());
  }

  Future<void> _loadBookings() async {
    final data = await bookingTable.getAllBookings();

    // Preload quotes referenced by bookings to avoid DB calls in the build loop
    final quoteIds = data.map((b) => b.quoteId).toSet().toList();
    final qMap = <int, Quote>{};
    for (final id in quoteIds) {
      try {
        final q = await quoteTable.getQuoteById(id);
        if (q != null && q.id != null) qMap[q.id!] = q;
      } catch (_) {}
    }

    setState(() {
      bookings = data;
      quoteById = qMap;
    });
  }
//preload clients
  Future<void> _loadClients() async {
    final data = await clientTable.getAllClients();

    final emailMap = <String, Client>{};
    final idMap = <int, Client>{};

    for (final c in data) {
      if (c.email.isNotEmpty) emailMap[c.email] = c;
      if (c.id != null) idMap[c.id!] = c;
    }

    setState(() {
      allClients = data;
      clientByEmail = emailMap;
      clientById = idMap;
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

    // Controller to auto-fill client field
    TextEditingController clientController = TextEditingController();

    // If editing a booking, select client and load quotes
    if (existing != null) {
      if (allClients.isNotEmpty) {
        selectedClient = allClients.firstWhere(
          (c) => c.id == existing.clientId,
          orElse: () => allClients.first,
        );

        if (selectedClient != null) {
          clientController.text =
              '${selectedClient.firstName} ${selectedClient.lastName} (${selectedClient.email})';
        }

        // load quotes defensively
        try {
          clientQuotes = await quoteTable.getQuotesByClient(selectedClient!.id!);
          if (clientQuotes.isNotEmpty &&
              (selectedQuoteId == null ||
                  !clientQuotes.any((q) => q.id == selectedQuoteId))) {
            selectedQuoteId = clientQuotes.first.id;
          }
        } catch (e) {
          clientQuotes = [];
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase().trim();
                      if (query.isEmpty) return const Iterable<String>.empty();
                      final matches = allClients.where((c) {
                        final full = '${c.firstName} ${c.lastName}'.toLowerCase();
                        return c.firstName.toLowerCase().contains(query) ||
                            c.lastName.toLowerCase().contains(query) ||
                            full.contains(query) ||
                            c.email.toLowerCase().contains(query);
                      }).map((c) => '${c.firstName} ${c.lastName} (${c.email})').toList();
                      return matches;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (clientController.text.isNotEmpty) {
                        controller.text = clientController.text; // Auto-fill on edit
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search client by name or email',
                          prefixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                    onSelected: (String selection) async {
                      final start = selection.lastIndexOf('(');
                      final end = selection.lastIndexOf(')');
                      String? email;
                      if (start != -1 && end != -1 && end > start) {
                        email = selection.substring(start + 1, end);
                      }

                      Client? client;
                      if (email != null) client = clientByEmail[email];

                      if (client == null) {
                        for (final c in allClients) {
                          final display = '${c.firstName} ${c.lastName} (${c.email})';
                          if (display == selection) {
                            client = c;
                            break;
                          }
                        }
                      }

                      if (client == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selected client not found')));
                        return;
                      }

                      try {
                        if (client.id == null) {
                          setStateDialog(() {
                            selectedClient = client;
                            clientQuotes = [];
                            selectedQuoteId = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Selected client is not saved (no id)')));
                          return;
                        }
                        final quotes = await quoteTable.getQuotesByClient(client.id!);
                        setStateDialog(() {
                          selectedClient = client;
                          clientQuotes = quotes;
                          selectedQuoteId =
                              clientQuotes.isNotEmpty ? clientQuotes.first.id : null;
                        });
                      } catch (e) {
                        setStateDialog(() {
                          selectedClient = client;
                          clientQuotes = [];
                          selectedQuoteId = null;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed loading quotes: $e')),
                          );
                        });
                      }
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      final opts = options.toList();
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: opts.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String display = opts[index];
                                final emailStart = display.lastIndexOf('(');
                                final namePart = emailStart > 0
                                    ? display.substring(0, emailStart).trim()
                                    : display;
                                final emailPart = (emailStart > 0 &&
                                        display.endsWith(')'))
                                    ? display.substring(
                                        emailStart + 1, display.length - 1)
                                    : '';
                                return ListTile(
                                  title: Text(namePart),
                                  subtitle:
                                      emailPart.isNotEmpty ? Text(emailPart) : null,
                                  onTap: () => onSelected(display),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
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
                  DropdownButtonFormField<String>(
                    value: status.isEmpty ? 'Scheduled' : status,
                    items: const [
                      DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'Finished', child: Text('Finished')),
                    ],
                    onChanged: (val) {
                      setStateDialog(() {
                        status = val ?? 'Scheduled';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                    isExpanded: true,
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
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () async {
                  if (selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a client.')),
                    );
                    return;
                  }
                  if (selectedQuoteId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a quote for this client.')),
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

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final timeColumnWidth = (screenWidth * 0.13).clamp(56.0, 120.0);
    final whiteSpaceWidth = (screenWidth * 0.06).clamp(32.0, 80.0);
    final remaining = screenWidth - timeColumnWidth - whiteSpaceWidth;
    double blockColumnWidth = (remaining / 7).clamp(36.0, 120.0);

    final cellHeight = (screenHeight * 0.07).clamp(40.0, 90.0);

    // font sizes relative to block width
    final dayNumberFont = (blockColumnWidth * 0.42).clamp(10.0, 20.0);
    final weekdayFont = (blockColumnWidth * 0.26).clamp(8.0, 14.0);
    final cellPrimaryFont = (blockColumnWidth * 0.22).clamp(8.0, 14.0);
    final cellSecondaryFont = (blockColumnWidth * 0.18).clamp(7.0, 12.0);

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
              // Dates (stacked Day / Weekday)
              for (int i = 0; i < days.length; i++)
                SizedBox(
                  width: blockColumnWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6),
                      Text(
                        days[i].day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: dayNumberFont,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        getWeekdayName(days[i]),
                        style: TextStyle(fontSize: weekdayFont, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                    ],
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
          const Divider(),
          // Hours + grid
          Expanded(
            child: ListView.builder(
              itemCount: hours.length,
              itemBuilder: (_, row) {
                final hour = hours[row];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      height: cellHeight,
                      child: Center(
                        child: Text(
                          "${hour.toString().padLeft(2, '0')}:00",
                          style: TextStyle(fontSize: cellPrimaryFont),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    for (final d in days)
                      SizedBox(
                        width: blockColumnWidth,
                        height: cellHeight,
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
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
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
                              borderRadius: BorderRadius.circular(6),
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
                                  // attempt to resolve client and quote from preloaded maps
                                  final client = clientById[booking.clientId];
                                  final quote = quoteById[booking.quoteId];
                                  final clientName = client != null ? '${client.firstName} ${client.lastName}' : '#${booking.clientId}';
                                  final quoteLabel = quote != null ? quote.description : '#${booking.quoteId}';

                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          clientName,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: cellPrimaryFont,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          quoteLabel,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: cellSecondaryFont),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
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
