import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final bookingTable = BookingTable();
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

  void _editBooking(DateTime slot, [Booking? existing]) {
    final customerController =
        TextEditingController(text: existing?.clientId.toString() ?? '');
    final statusController =
        TextEditingController(text: existing?.status ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'New Booking' : 'Edit Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerController,
              decoration: const InputDecoration(labelText: 'Client ID'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Status (Optional)'),
            ),
          ],
        ),
        actions: [
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
              int clientId =
                  int.tryParse(customerController.text.trim()) ?? 1;
              String status =
                  statusController.text.trim().isEmpty ? "Scheduled" : statusController.text.trim();

              if (existing != null) {
                Booking updated = Booking(
                  bookingId: existing.bookingId,
                  clientId: clientId,
                  bookingDate: slot,
                  status: status,
                  createdAt: existing.createdAt,
                );
                await bookingTable.updateBooking(updated);
              } else {
                Booking newBooking = Booking(
                  clientId: clientId,
                  bookingDate: slot,
                  status: status,
                );
                await bookingTable.insertBooking(newBooking);
              }

              Navigator.pop(context);
              _loadBookings();
            },
            child: const Text('Save'),
          ),
        ],
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

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Calendar')),
      body: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 70), // Padding for time column
              for (int i = 0; i < days.length; i++)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousWeek,
                          tooltip: 'Previous Week',
                        ),
                      Text(
                        "${days[i].day.toString().padLeft(2, '0')}/${days[i].month.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (i == days.length - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextWeek,
                          tooltip: 'Next Week',
                        ),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 70), // Padding for time column
              for (final d in days)
                Expanded(
                  child: Center(
                    child: Text(
                      getWeekdayName(d),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
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
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 0.0),
                      child: SizedBox(
                        width: 60,
                        child: Text(
                          "$hour:00",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    for (final d in days)
                      Expanded(
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
                                      "Client: ${booking.clientId}\n${booking.status}",
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