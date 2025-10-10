import 'package:flutter/material.dart';
import 'package:shutterbook/data/database_helper.dart';
import 'package:shutterbook/data/models/booking.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final db = DatabaseHelper.instance; 
  List<Booking> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings(); 
  }

  Future<void> _loadBookings() async {
    final data = await db.getAllBookings();
    setState(() {
      bookings = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return ListTile(
            title: Text('Booking #${booking.bookingId}'),
            subtitle: Text(booking.status),
          );
        },
      ),
    );
  }
}
