import 'package:flutter/foundation.dart';
import '../Utilities/auth_services.dart';

class AuthModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _hasPassword = false;
  bool _biometricEnabled = false;

  bool get hasPassword => _hasPassword;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> loadSettings() async {
    _hasPassword = await _authService.hasPassword();
    _biometricEnabled = await _authService.getBiometricStatus();
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    await _authService.savePassword(password);
    _hasPassword = true;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    await _authService.savePassword(newPassword);
    notifyListeners();
  }

  Future<void> removePassword() async {
    await _authService.clearPassword();
    _hasPassword = false;
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _authService.setBiometricStatus(value);
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<bool> authenticate() async {
    return await _authService.authenticate();
  }

  Future<bool> isFirstLaunch() async {
    return await _authService.isFirstLaunch();
  }

  Future<bool> verifyPassword(String input) async {
    return await _authService.verifyPassword(input);
  }
}
