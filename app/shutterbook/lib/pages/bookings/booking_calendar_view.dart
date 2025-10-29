import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

class BookingCalendarView extends StatefulWidget {
  const BookingCalendarView({super.key});

  @override
  State<BookingCalendarView> createState() => _BookingCalendarViewState();
}

class _BookingCalendarViewState extends State<BookingCalendarView> {
  final bookingTable = BookingTable();
  final quoteTable = QuoteTable();
  final clientTable = ClientTable();

  List<Booking> bookings = [];
  List<Client> allClients = [];
  Map<String, Client> clientByEmail = {};

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
    final map = <String, Client>{};
    for (final c in data) {
      if (c.email.isNotEmpty) map[c.email] = c;
    }
    setState(() {
      allClients = data;
      clientByEmail = map;
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

    if (existing != null) {
      if (allClients.isNotEmpty) {
        selectedClient = allClients.firstWhere(
          (c) => c.id == existing.clientId,
          orElse: () => allClients.first,
        );
        try {
          clientQuotes = await quoteTable.getQuotesByClient(selectedClient.id!);
          if (clientQuotes.isNotEmpty &&
              (selectedQuoteId == null ||
                  !clientQuotes.any((q) => q.id == selectedQuoteId))) {
            selectedQuoteId = clientQuotes.first.id;
          }
        } catch (e) {
          clientQuotes = [];
        }
      } else {
        selectedClient = null;
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
                      final matches = allClients
                          .where((c) {
                            final full = '${c.firstName} ${c.lastName}'.toLowerCase();
                            return c.firstName.toLowerCase().contains(query) ||
                                c.lastName.toLowerCase().contains(query) ||
                                full.contains(query) ||
                                c.email.toLowerCase().contains(query);
                          })
                          .map((c) => '${c.firstName} ${c.lastName} (${c.email})')
                          .toList();
                      return matches;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                          selectedQuoteId = clientQuotes.isNotEmpty ? clientQuotes.first.id : null;
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
                                final namePart =
                                    emailStart > 0 ? display.substring(0, emailStart).trim() : display;
                                final emailPart = (emailStart > 0 && display.endsWith(')'))
                                    ? display.substring(emailStart + 1, display.length - 1)
                                    : '';
                                return ListTile(
                                  title: Text(namePart),
                                  subtitle: emailPart.isNotEmpty ? Text(emailPart) : null,
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
                    initialValue: selectedQuoteId,
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
                    initialValue: status.isEmpty ? 'Scheduled' : status,
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
                    if (!mounted) return;
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
    // const double blockColumnWidth = 44; // responsive below
    const double whiteSpaceWidth = 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isPhone = constraints.maxWidth < 480;
        final double timeCol = isPhone ? 48 : timeColumnWidth;
        final double whiteCol = isPhone ? 24 : whiteSpaceWidth;
        const double minBlock = 40;

        final double fitBlock = (constraints.maxWidth - timeCol - whiteCol) / 7.0;
        final bool needsHScroll = fitBlock < minBlock;
        final double blockW = needsHScroll ? minBlock : fitBlock.floorToDouble();
        final double contentW = timeCol + whiteCol + (blockW * 7);

        Widget buildDateRow() {
          final row = Row(
            children: [
              SizedBox(
                width: timeCol,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousWeek,
                  tooltip: 'Previous Week',
                ),
              ),
              for (int i = 0; i < days.length; i++)
                SizedBox(
                  width: blockW,
                  child: Center(
                    child: Text(
                      "${days[i].day.toString().padLeft(2, '0')}/${days[i].month.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              SizedBox(
                width: whiteCol,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextWeek,
                  tooltip: 'Next Week',
                ),
              ),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        Widget buildDaysRow() {
          final row = Row(
            children: [
              SizedBox(width: timeCol),
              for (final d in days)
                SizedBox(
                  width: blockW,
                  child: Center(
                    child: Text(
                      getWeekdayName(d),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              SizedBox(width: whiteCol),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        Widget buildHourRow(int hour) {
          final row = Row(
            children: [
              SizedBox(
                width: timeCol,
                child: Text(
                  "$hour:00",
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              for (final d in days)
                SizedBox(
                  width: blockW,
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
              SizedBox(width: whiteCol),
            ],
          );
          if (needsHScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentW, child: row),
            );
          }
          return row;
        }

        return Column(
          children: [
            buildDateRow(),
            buildDaysRow(),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: hours.length,
                itemBuilder: (_, row) {
                  final hour = hours[row];
                  return buildHourRow(hour);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
