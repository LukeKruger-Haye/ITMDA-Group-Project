// Shutterbook — booking_calendar_view.dart
// ignore_for_file: use_build_context_synchronously
// A compact calendar view used in the bookings section to visualise
// upcoming sessions. It's intentionally small and focused on display logic.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/services/data_cache.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/pages/bookings/bookings_inventory_page.dart';

class BookingCalendarView extends StatefulWidget {
  const BookingCalendarView({super.key});

  @override
  State<BookingCalendarView> createState() => _BookingCalendarViewState();
}

class _BookingCalendarViewState extends State<BookingCalendarView> {
  final bookingTable = BookingTable();
  final quoteTable = QuoteTable();
  // clientTable retained for writes; reads should use DataCache for better perf
  final clientTable = ClientTable();

  List<Booking> bookings = [];
  List<Client> allClients = [];
  Map<String, Client> clientByEmail = {};

  late DateTime weekStart;
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
  _loadBookings();
  _loadClients();
  }

  @override
  void dispose() {
    // Space for later timers
    super.dispose();
  }
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = wk[dt.weekday - 1];
    final month = mo[dt.month - 1];
    final hour = _twoDigits(dt.hour);
    final min = _twoDigits(dt.minute);
    return '$day, ${dt.day} $month • $hour:$min';
  }

  Future<void> _loadBookings() async {
    final data = await bookingTable.getAllBookings();
    if (!mounted) return;
    setState(() => bookings = data);
  }

  Future<void> _loadClients() async {
    final data = await clientTable.getAllClients();
    final map = <String, Client>{};
    for (final c in data) {
      if (c.email.isNotEmpty) map[c.email] = c;
    }
    if (!mounted) return;
    setState(() {
      allClients = data;
      clientByEmail = map;
    });
  }

  // Determine a background color for a booking status using the current theme
  Color getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    switch (status.toLowerCase()) {
      case 'scheduled':
        // Use primaryContainer for scheduled to adapt to dark/light themes
        return cs.primaryContainer;
      case 'completed':
        return cs.secondaryContainer;
      case 'cancelled':
        return cs.errorContainer;
      default:
        return cs.surfaceContainerHighest;
    }
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

  Client? getClientForBooking(Booking booking) {
    try {
      return allClients.firstWhere((c) => c.id == booking.clientId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editBooking(DateTime slot, [Booking? existing]) async {
    Client? selectedClient;
    if (existing != null) {
      // Booking.clientId is non-nullable in our model, so we can access it directly.
      selectedClient = await clientTable.getClientById(existing.clientId);
    }
    _selectedDateTime = existing?.bookingDate;

    List<Quote> clientQuotes = [];
    int? selectedQuoteId = existing?.quoteId;
    String status = existing?.status ?? 'Scheduled';

    if (selectedClient != null && selectedClient.id != null) {
      clientQuotes = await quoteTable.getQuotesByClient(selectedClient.id!);
    }

    final TextEditingController searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogMessenger = ScaffoldMessenger.of(dialogContext);
        final dialogNavigator = Navigator.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<Client> filteredClients = allClients
                .where((c) =>
                    c.firstName.toLowerCase().contains(searchController.text.toLowerCase()) ||
                    c.lastName.toLowerCase().contains(searchController.text.toLowerCase()) ||
                    c.email.toLowerCase().contains(searchController.text.toLowerCase()))
                .toList();

            if (selectedClient != null && !filteredClients.contains(selectedClient)) {
              filteredClients.insert(0, selectedClient!);
            }

            return AlertDialog(
              title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Dropdown
                    DropdownButtonFormField<Client>(
                      initialValue: selectedClient,
                      items: filteredClients
                          .map(
                            (c) => DropdownMenuItem<Client>(
                              value: c,
                              child: Text('${c.firstName} ${c.lastName} (${c.email})'),
                            ),
                          )
                          .toList(),
                      onChanged: (Client? client) async {
                        if (client == null) return;
                        final quotes = await quoteTable.getQuotesByClient(client.id!);
                        setStateDialog(() {
                          selectedClient = client;
                          clientQuotes = quotes;
                          selectedQuoteId = clientQuotes.isNotEmpty ? clientQuotes.first.id : null;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select client',
                        prefixIcon: Icon(Icons.person),
                      ),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 8),
                    // Quote Dropdown
                    DropdownButtonFormField<int>(
                      initialValue: selectedQuoteId,
                      items: clientQuotes
                          .map((q) => DropdownMenuItem<int>(
                                value: q.id!,
                               child: Text('${q.description} (Quote #${q.id})'),
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
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: () {
                        switch (status.toLowerCase()) {
                          case 'finished':
                          case 'completed':
                            return 'Completed';
                          case 'cancelled':
                            return 'Cancelled';
                          default:
                            return 'Scheduled';
                        }
                      }(),
                      items: [
                        const DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                        if (existing != null)
                          const DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                          if (existing != null)
                        const DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          status = val ?? 'Scheduled';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    // Date/Time Picker Button only for editing existing bookings
                    if (existing != null)
                      OutlinedButton.icon(
                        style: UIStyles.outlineButton(context),
                        onPressed: () async {
                          final now = DateTime.now();
                          final initialDate = _selectedDateTime ?? now;

                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 3),
                          );
                          if (pickedDate == null) return;

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(initialDate),
                          );
                          if (pickedTime == null) return;

                          setStateDialog(() {
                            _selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.event),
                        label: Text(
                          _selectedDateTime == null ? 'Select Date & Time' : _formatDateTime(_selectedDateTime!),
                        ),
                      ),
                      //Manage inventory for bookings button
                    if (existing != null) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingInventoryPage(
                                  bookingId: existing.bookingId!,
                                ),
                              ),
                            );
                            if (mounted) {
                              _loadBookings(); // refresh bookings after return
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Inventory updated for this booking')),
                              );
                            }
                          },
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Add / Edit Inventory'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
                actions: [
                  TextButton(
                    onPressed: () => dialogNavigator.pop(),
                    child: const Text('Cancel'),
                  ),
                  if (existing != null)
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: dialogContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text('Are you sure you want to delete this booking?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        await bookingTable.deleteBooking(existing.bookingId!);
                        if (dialogNavigator.mounted) dialogNavigator.pop();
                        if (!mounted) return;
                        _loadBookings();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  TextButton(
                    onPressed: () async {
                      if (selectedClient == null) {
                        dialogMessenger.showSnackBar(const SnackBar(content: Text('Please select a client.')));
                        return;
                      }
                      if (selectedQuoteId == null) {
                        dialogMessenger.showSnackBar(const SnackBar(content: Text('Please select a quote for this client.')));
                        return;
                      }

                      // Double-booking check for this hour slot
                      final conflicts = await bookingTable.findHourConflicts(
                        slot,
                        excludeBookingId: existing?.bookingId,
                      );
                      if (conflicts.isNotEmpty) {
                        final proceed = await showDialog<bool>(
                          context: dialogContext,
                          builder: (innerCtx) => AlertDialog(
                            title: const Text('Possible double booking'),
                            content: Text('There is already ${conflicts.length} booking(s) in this time slot (hour).\n\nYou can edit the time or proceed and allow a double booking.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(innerCtx).pop(false),
                                child: const Text('Edit time'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(innerCtx).pop(true),
                                child: const Text('Proceed'),
                              ),
                            ],
                          ),
                        ) ??
                            false;
                        if (!proceed) return;
                      }

                      final bookingDate = _selectedDateTime ?? slot;

                      // Enforce 08:00–18:00
                      if (bookingDate.hour < 8 || bookingDate.hour > 18) {
                        dialogMessenger.showSnackBar(const SnackBar(
                          content: Text('Please select a time between 08:00 and 18:00.'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      // Check for conflicting bookings at the specific hour
                      final conflict = bookings.any((b) =>
                          b.bookingDate.year == bookingDate.year &&
                          b.bookingDate.month == bookingDate.month &&
                          b.bookingDate.day == bookingDate.day &&
                          b.bookingDate.hour == bookingDate.hour &&
                          (existing == null || b.bookingId != existing.bookingId));

                      if (conflict) {
                        dialogMessenger.showSnackBar(const SnackBar(
                          content: Text('This time slot is already booked. Please choose another.'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      if (existing != null) {
                        final updated = Booking(
                          bookingId: existing.bookingId,
                          quoteId: selectedQuoteId!,
                          clientId: selectedClient!.id!,
                          bookingDate: bookingDate,
                          status: status.isEmpty ? 'Scheduled' : status,
                          createdAt: existing.createdAt,
                        );
                        await bookingTable.updateBooking(updated);
                        DataCache.instance.clearBookings();
                        setState(() {
                          final index = bookings.indexWhere((b) => b.bookingId == existing.bookingId);
                          if (index != -1) bookings[index] = updated;
                        });
                      } else {
                        final newBooking = Booking(
                          quoteId: selectedQuoteId!,
                          clientId: selectedClient!.id!,
                          bookingDate: bookingDate,
                          status: status.isEmpty ? 'Scheduled' : status,
                        );
                        await bookingTable.insertBooking(newBooking);
                        DataCache.instance.clearBookings();
                      }

                      if (dialogNavigator.mounted) dialogNavigator.pop();
                      if (!mounted) return;
                      _loadBookings();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
          },
        );
      },
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
                  child: Builder(builder: (context) {
                    final slot = DateTime(d.year, d.month, d.day, hour);
                    final booking = getBookingForSlot(slot);
                    

                    final bool isNewBookingBlocked = hour < 8 || hour > 18 || booking != null;

                    return GestureDetector(
                      onTap: () {
                        if (booking != null) {
                          _editBooking(slot, booking);
                        } else if (!isNewBookingBlocked) {
                          _editBooking(slot);
                        }
                      },
                        child: Container(
                        margin: const EdgeInsets.all(2),
                        height: 50,
                        decoration: BoxDecoration(
                          color: booking != null
                              ? getStatusColor(context, booking.status)
                              : (hour < 8 || hour > 18
                                  ? const Color.fromARGB(255, 24, 20, 20)
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: booking != null
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        getClientForBooking(booking)?.firstName ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Color.fromARGB(255, 12, 12, 12),
                                        ),
                                      ),
                                      Text(
                                        getClientForBooking(booking)?.lastName ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9, color: Color.fromARGB(255, 34, 29, 29)),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
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