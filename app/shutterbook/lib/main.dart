import 'package:flutter/material.dart';
import 'package:shutterbook/dashboard.dart';
import 'pages/authentication/models/auth_model.dart';
import 'pages/authentication/login.dart';
import 'pages/authentication/auth_setup.dart';
import 'pages/home.dart';
import 'pages/quotes/quotes.dart';
import 'pages/bookings/bookings.dart';
import 'pages/clients/clients.dart';
import 'pages/quotes/create/create_quote.dart';
import 'pages/quotes/manage/manage_quote_screen.dart';

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
            title: 'Shutterbook',
            theme: ThemeData(primarySwatch: Colors.amber),
            routes: {
                '/quotes': (context) => const QuotePage(),
                '/bookings': (context) => const BookingsPage(),
                'clients': (context) => const ClientsPage(),
                '/quotes/create/create_quote.dart': (context) => const CreateQuotePage(),
                '/quotes/manage/manage_quote_screen.dart': (context) => const ManageQuotePage(),
                '/dashboard': (context) => const DashboardPage(),
            },
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
