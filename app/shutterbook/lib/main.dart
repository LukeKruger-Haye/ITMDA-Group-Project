import 'package:flutter/material.dart';
import 'package:shutterbook/data/db/database_helper.dart';
import 'pages/theme_controller.dart';
import 'pages/bookings/dashboard.dart';
import 'pages/authentication/models/auth_model.dart';
import 'pages/authentication/login.dart';
import 'pages/authentication/auth_setup.dart';
import 'pages/home.dart';
import 'pages/quotes/quotes.dart';
import 'pages/bookings/bookings.dart';
import 'pages/clients/clients.dart';
import 'pages/quotes/create/create_quote.dart';
import 'pages/quotes/manage/manage_quote_screen.dart';
import 'pages/inventory/inventory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;
  await ThemeController.instance.init();

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
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Local Auth App',
          theme: ThemeData(primarySwatch: Colors.amber),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routes: {
            '/quotes': (context) => const QuotePage(),
            '/clients': (context) => const ClientsPage(),
            '/bookings': (context) => const BookingsPage(),
            '/quotes/create': (context) => const CreateQuotePage(),
            '/quotes/manage': (context) => const ManageQuotePage(),
            '/dashboard': (context) => const DashboardPage(),
            '/inventory': (context) => const InventoryPage(),
          },
          home: Builder(builder: (context) {
            if (firstLaunch) {
              return SetupScreen(authModel: authModel);
            }

            if (authModel.hasPassword) {
              return LoginScreen(authModel: authModel);
            }

            return HomeScreen(authModel: authModel);
          }),
        );
      },
    );
  }
}
