import 'package:flutter/material.dart';
import '../Models/auth_model.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthModel authModel;

  const LoginScreen({super.key, required this.authModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _biometricTried = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin() async {
    if (widget.authModel.biometricEnabled && widget.authModel.hasPassword) {
      setState(() => _isLoading = true);
      final success = await widget.authModel.authenticate();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _biometricTried = true;
      });

      if (success) {
        _goToHome();
      }
    } else {
      _biometricTried = true;
    }
  }

  Future<void> _loginWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);
    final valid = await widget.authModel.verifyPassword(password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (valid) {
      _goToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(authModel: widget.authModel),
      ),
    );
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    final success = await widget.authModel.authenticate();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _goToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricsOn =
        widget.authModel.hasPassword && widget.authModel.biometricEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Enter password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: _loginWithPassword,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  if (biometricsOn && _biometricTried)
                    IconButton(
                      onPressed: _loginWithBiometric,
                      icon: const Icon(Icons.fingerprint, size: 40),
                      tooltip: 'Use biometrics',
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
