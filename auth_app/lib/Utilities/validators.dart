class Validators {
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    // Optionally, enforce: uppercase, numbers, symbols
    return null;
  }
}
