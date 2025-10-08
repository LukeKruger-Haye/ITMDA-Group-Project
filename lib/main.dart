import 'dart:collection';
import 'package:flutter/material.dart';

void main() {
  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photography Booking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BookingScreen(),
    );
  }
}

// LinkedList 
base class Booking extends LinkedListEntry<Booking> {
  String customerName;
  String location;
  DateTime time;

  Booking({
    required this.customerName,
    required this.location,
    required this.time,
  })  : super();
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final LinkedList<Booking> bookings = LinkedList<Booking>();

  
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
  }

  Booking? getBookingForSlot(DateTime slot) {
    try {
      return bookings.firstWhere((b) =>
          b.time.year == slot.year &&
          b.time.month == slot.month &&
          b.time.day == slot.day &&
          b.time.hour == slot.hour);
    } catch (_) {
      return null;
    }
  }

  void _editBooking(DateTime slot, [Booking? booking]) {
    final customerController =
        TextEditingController(text: booking?.customerName ?? '');
    final locationController =
        TextEditingController(text: booking?.location ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(booking == null ? 'New Booking' : 'Edit Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          if (booking != null)
            TextButton(
              onPressed: () {
                setState(() {
                  booking.unlink(); // remove booking
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                if (booking != null) {
                  booking.customerName = customerController.text;
                  booking.location = locationController.text;
                } else {
                  bookings.add(Booking(
                    customerName: customerController.text,
                    location: locationController.text,
                    time: slot,
                  ));
                }
              });
              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(10, (i) => 8 + i); // 8AM to 6PM
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Calendar')),
      body: Column(
        children: [
          // Days header with arrows
          Row(
            children: [
              const SizedBox(width: 60), 
              for (int i = 0; i < days.length; i++)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 0) // Left arrow before first day
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousWeek,
                          tooltip: 'Previous Week',
                        ),
                      Text(
                        "${days[i].month}/${days[i].day}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (i == days.length - 1) // Right arrow after last day
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
          const Divider(),
          // Grid
          Expanded(
            child: ListView.builder(
              itemCount: hours.length,
              itemBuilder: (_, row) {
                final hour = hours[row];
                return Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text("$hour:00",
                          style: const TextStyle(fontSize: 12)),
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
                                  return Colors.green[300]; // booked = green
                                }
                                return Colors.grey[200]; // empty = grey
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
                                      "${booking.customerName}\n${booking.location}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
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
