// Shutterbook — formatters.dart
// Tiny, focused formatting helpers used across the app. Kept intentionally
// minimal to avoid pulling in heavy locale packages. Replace with `intl`
// if you need locale-aware formatting in the future.

/// Format a numeric value as South African Rand with two decimal places.
String formatRand(double value) {
  const currency = 'R';
  return '$currency${value.toStringAsFixed(2)}';
}
