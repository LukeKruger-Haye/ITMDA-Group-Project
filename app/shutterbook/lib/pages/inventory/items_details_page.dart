import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/models/booking.dart';
import '../../data/tables/booking_inventory_table.dart';
import '../../data/tables/booking_table.dart';
import '../../data/models/booking_with_client.dart';
import '../../data/tables/inventory_table.dart';
import '../../data/services/data_cache.dart';
import '../../data/models/item.dart';

class InventoryDetailsPage extends StatefulWidget {
  final Item item;

  const InventoryDetailsPage({Key? key, required this.item}) : super(key: key);

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
                  Text('Category: ${item.category ?? "Unspecified"}'),
                  Text('Condition: ${item.condition ?? "Unknown"}'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // EDIT BUTTON
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () async {
                          String name = item.name;
                          String category = item.category;
                          String condition = item.condition;

                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Edit Item'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: TextEditingController(text: name),
                                        decoration:
                                            const InputDecoration(labelText: 'Item Name'),
                                        onChanged: (val) => name = val,
                                      ),
                                      TextField(
                                        controller: TextEditingController(text: category),
                                        decoration:
                                            const InputDecoration(labelText: 'Category'),
                                        onChanged: (val) => category = val,
                                      ),
                                      DropdownButtonFormField<String>(
                                        decoration:
                                            const InputDecoration(labelText: 'Condition'),
                                        value: condition,
                                        items: ['New', 'Excellent', 'Good', 'Needs Repair']
                                            .map((e) =>
                                                DropdownMenuItem(value: e, child: Text(e)))
                                            .toList(),
                                        onChanged: (val) => condition = val ?? 'Good',
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (name.trim().isEmpty ||
                                          category.trim().isEmpty ||
                                          condition.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Please fill in all fields before saving.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      final updatedItem = Item(
                                        id: item.id,
                                        name: name.trim(),
                                        category: category.trim(),
                                        condition: condition.trim(),
                                        imagePath: item.imagePath,
                                        serialNumber: item.serialNumber,
                                      );

                                      await InventoryTable().updateItem(updatedItem);
                                      DataCache.instance.clearInventory();
                                      if (mounted) {
                                        setState(() {
                                          widget.item.name = updatedItem.name;
                                          widget.item.category = updatedItem.category;
                                          widget.item.condition = updatedItem.condition;
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Item "${updatedItem.name}" updated successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      // DELETE BUTTON
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Item'),
                              content: const Text(
                                  'Are you sure you want to delete this item? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await InventoryTable().deleteItem(item.id!);
                            DataCache.instance.clearInventory();
                            if (mounted) {
                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item "${item.name}" deleted successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  )
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