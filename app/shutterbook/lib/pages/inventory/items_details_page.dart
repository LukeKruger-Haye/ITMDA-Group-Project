import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/tables/booking_table.dart';
import '../../data/models/booking_with_client.dart';


class InventoryDetailsPage extends StatefulWidget {
  final Item item;

  const InventoryDetailsPage({super.key, required this.item});

  @override
  State<InventoryDetailsPage> createState() => _InventoryDetailsPageState();
}

class _InventoryDetailsPageState extends State<InventoryDetailsPage> {
  late Future<List<BookingWithClient>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = BookingTable()
          .getBookingsForItemWithClientNames(widget.item.id!); // correct query
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1 — ITEM INFO
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (item.imagePath != null && item.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(item.imagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.image_not_supported,
                        size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Category: ${item.category}'),
                  Text('Condition: ${item.condition}'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () {
                          // Edit logic
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () {
                          // Delete logic
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TAB 2 — BOOKINGS TAB
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Linked Bookings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh bookings',
                        onPressed: _loadBookings,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _bookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No bookings found.'));
                      }

                      final allBookings = snapshot.data!;

                      // Group bookings based on their status
                      final upcoming = allBookings
                          .where((b) =>
                              (b.status.toLowerCase() == 'scheduled' ||
                              b.status.toLowerCase() == 'pending'))
                          .toList();

                      final past = allBookings
                          .where((b) => b.status.toLowerCase() == 'completed' ||
                                        b.status.toLowerCase() == 'complete')
                          .toList();

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upcoming bookings
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Upcoming Bookings',
                                style:
                                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (upcoming.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No upcoming bookings.'),
                              )
                            else
                              ...upcoming.map((b) => Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading:
                                          const Icon(Icons.event_available, color: Colors.green),
                                      title: Text(b.clientName ?? 'Unknown Client'),
                                      subtitle: Text(
                                          'On ${b.bookingDate.toLocal()} — ${b.status}'),
                                    ),
                                  )),

                            // Past bookings
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Past Bookings',
                                style:
                                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (past.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No past bookings.'),
                              )
                            else
                              ...past.map((b) => Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading:
                                          const Icon(Icons.history, color: Colors.blueGrey),
                                      title: Text(b.clientName ?? 'Unknown Client'),
                                      subtitle: Text(
                                          'On ${b.bookingDate.toLocal()} — ${b.status}'),
                                    ),
                                  )),
                          ],
                        ),
          );
        },
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}