import 'package:flutter/material.dart';
import '../Models/auth_model.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final AuthModel authModel;

  const SetupScreen({super.key, required this.authModel});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _usePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_usePassword) {
      final pw = _passwordController.text.trim();
      if (pw.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password must be at least 4 characters long')),
        );
        return;
      }
      await widget.authModel.setPassword(pw);

      // Prompt to enable biometrics if available
      final canUseBiometric = await widget.authModel.authenticate();
      if (canUseBiometric) {
        await widget.authModel.setBiometricEnabled(true);
      }
    } else {
      await widget.authModel.removePassword();
      await widget.authModel.setBiometricEnabled(false);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(authModel: widget.authModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Setup')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SwitchListTile(
                  title: const Text('Enable Password Lock'),
                  value: _usePassword,
                  onChanged: (v) => setState(() => _usePassword = v),
                ),
                if (_usePassword) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Set a password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
