import 'package:flutter/material.dart';

/// Centralized app colors used for subtle tab accents.
class AppColors {
  // keep these subtle and accessible
  static const List<Color> tabColors = [
    Color(0xFF1565C0), // Dashboard - blue
    Color(0xFF00796B), // Bookings - teal
    Color(0xFF6A1B9A), // Clients - purple
    Color(0xFFF57C00), // Quotes - orange
    Color(0xFF2E7D32), // Inventory - green
  ];

  static Color colorForIndex(int index) => tabColors[index % tabColors.length];
}
