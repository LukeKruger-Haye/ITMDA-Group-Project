import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // This would be replaced with data fetched from SQLite database

  final List<Map<String, String>> bookings = const [
    {
      'title': 'Booking 1',
      'subtitle': 'Portrait Session',
      'details': 'Date: 2024-07-01\nLocation: Studio A',
    },
    {
      'title': 'Booking 2',
      'subtitle': 'Wedding Shoot',
      'details': 'Date: 2024-07-05\nLocation: Beachside',
    },
    {
      'title': 'Booking 3',
      'subtitle': 'Product Photography',
      'details': 'Date: 2024-07-10\nLocation: Client Office',
    },
    {
      'title': 'Booking 4',
      'subtitle': 'Family Portrait',
      'details': 'Date: 2024-07-12\nLocation: Park',
    },
    {
      'title': 'Booking 5',
      'subtitle': 'Event Coverage',
      'details': 'Date: 2024-07-15\nLocation: Convention Center',
    },
    {
      'title': 'Booking 6',
      'subtitle': 'Fashion Shoot',
      'details': 'Date: 2024-07-18\nLocation: Rooftop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photography Bookings Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: bookings.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            // Automatically chooses 1–3 columns based on available width
            maxCrossAxisExtent: 320,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    Text(
                      booking['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking['subtitle'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking['details'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// TODO: Replace the static bookings list with data fetched from SQLite database
// Example: Use sqflite package to query bookings and update the bookings list