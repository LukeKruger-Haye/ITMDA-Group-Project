import 'package:flutter/material.dart';
import '../authentication/models/auth_model.dart';
import '../authentication/auth_setup.dart';
import '../theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final AuthModel authModel;

  const SettingsScreen({super.key, required this.authModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  bool _usePassword = false;
  bool _useBiometric = false;
  bool _useDark = false;

  @override
  void initState() {
    super.initState();
    _load();
    ThemeController.instance.isDark.addListener(_themeListener);
  }

  void _themeListener() {
    if (!mounted) return;
    setState(() => _useDark = ThemeController.instance.isDark.value);
  }

  @override
  void dispose() {
    ThemeController.instance.isDark.removeListener(_themeListener);
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await widget.authModel.loadSettings();
    // ThemeController should be initialized in main(), but read current value here:
    setState(() {
      _usePassword = widget.authModel.hasPassword;
      _useBiometric = widget.authModel.biometricEnabled;
      _useDark = ThemeController.instance.isDark.value;
    });
  }

  Future<void> _changePassword() async {
    final newPw = _newPasswordController.text.trim();
    if (newPw.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters')),
      );
      return;
    }
    await widget.authModel.changePassword(newPw);
    _newPasswordController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed')),
    );
  }

  Future<void> _togglePassword(bool value) async {
    if (!value) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disable password lock?'),
          content:
              const Text('This will remove the password and disable biometrics.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disable')),
          ],
        ),
      );

      if (ok != true) return;

      await widget.authModel.removePassword();
      await widget.authModel.setBiometricEnabled(false);

      if (!mounted) return;
      setState(() {
        _usePassword = false;
        _useBiometric = false;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SetupScreen(authModel: widget.authModel)),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!widget.authModel.hasPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable password lock first to use biometrics'),
        ),
      );
      return;
    }
    await widget.authModel.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _useBiometric = value);
  }

  Future<void> _toggleDark(bool value) async {
    await ThemeController.instance.setDark(value);
    if (!mounted) return;
    setState(() => _useDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Password Lock'),
              value: _usePassword,
              onChanged: _togglePassword,
            ),
            if (_usePassword) ...[
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _changePassword, child: const Text('Change Password')),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Enable Biometrics'),
                value: _useBiometric,
                onChanged: _toggleBiometric,
              ),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _useDark,
              onChanged: _toggleDark,
            ),
          ],
        ),
      ),
    );
  }
}
