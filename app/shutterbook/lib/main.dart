import 'package:flutter/material.dart';
import 'pages/authentication/models/auth_model.dart';
import 'pages/authentication/login.dart';
import 'pages/authentication/auth_setup.dart';
import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authModel = AuthModel();
  await authModel.loadSettings();

  final firstLaunch = await authModel.isFirstLaunch();

  runApp(MyApp(authModel: authModel, firstLaunch: firstLaunch));
}

class MyApp extends StatelessWidget {
  final AuthModel authModel;
  final bool firstLaunch;

  const MyApp({super.key, required this.authModel, required this.firstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Auth App',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: Builder(builder: (context) {
        if (firstLaunch) {
          return SetupScreen(authModel: authModel);
        } else if (authModel.hasPassword) {
          return LoginScreen(authModel: authModel);
        } else {
          return HomeScreen(authModel: authModel);
        }
      }),
    );
  }
}
