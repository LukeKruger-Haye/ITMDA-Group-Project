import 'package:flutter/material.dart';

/// Centralized UI styles for small, low-risk consistency fixes.
/// Keep this file deliberately small: it provides a few button styles
/// and spacing constants used across screens.
class UIStyles {
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  // Slight elevation so cards appear lifted and not completely flat.
  // Increased to improve visual separation from the scaffold background.
  static const double cardElevation = 4.0;

  static ButtonStyle primaryButton(BuildContext context) {
    final t = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: t.colorScheme.primary,
      foregroundColor: t.colorScheme.onPrimary,
      textStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ButtonStyle destructiveButton(BuildContext context) {
    final t = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: t.colorScheme.error,
      foregroundColor: t.colorScheme.onError,
      textStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static ButtonStyle outlineButton(BuildContext context) {
    final t = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: t.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
