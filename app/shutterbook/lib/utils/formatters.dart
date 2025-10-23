// Small formatter helpers used across the app.
// Kept minimal to avoid adding external dependencies. If you want
// locale-aware formatting (grouping, locales), consider adding
// the `intl` package and using NumberFormat.currency.

String formatRand(double value) {
  // Ensure two decimal places and a leading R symbol used in South Africa.
  return 'R${value.toStringAsFixed(2)}';
}
