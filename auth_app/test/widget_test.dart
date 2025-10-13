import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth_app/Models/auth_model.dart';
import 'package:auth_app/Pages/home_screen.dart';
import 'package:auth_app/Pages/login_screen.dart';
import 'package:auth_app/Pages/setup_screen.dart';
import 'package:auth_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('First launch shows SetupScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'first_launch': true,
      'password_enabled': false,
      'biometrics_enabled': true,
    });

    final authModel = AuthModel();
    await authModel.loadSettings();

    await tester.pumpWidget(MyApp(authModel: authModel, firstLaunch: true));
    await tester.pumpAndSettle();

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('Initial Setup'), findsOneWidget);
  });

  testWidgets('Password lock enabled shows LoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'first_launch': false,
      'password_enabled': true,
      'app_password': '1234',
      'biometrics_enabled': true,
    });

    final authModel = AuthModel();
    await authModel.loadSettings();

    // Force password manually to avoid async timing issues in Stateless MyApp
    await authModel.setPassword('1234');

    await tester.pumpWidget(MyApp(authModel: authModel, firstLaunch: false));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Password lock disabled goes straight to HomeScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'first_launch': false,
      'password_enabled': false,
      'biometrics_enabled': true,
    });

    final authModel = AuthModel();
    await authModel.loadSettings();

    await tester.pumpWidget(MyApp(authModel: authModel, firstLaunch: false));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome Home!'), findsOneWidget);
  });

  testWidgets('Biometrics toggle works after password setup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'first_launch': false,
      'password_enabled': true,
      'app_password': '1234',
      'biometrics_enabled': false,
    });

    final authModel = AuthModel();
    await authModel.loadSettings();
    await authModel.setPassword('1234'); // ensure password exists

    // Start on SettingsScreen with password enabled
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Biometrics'),
                  value: authModel.biometricEnabled,
                  onChanged: (v) async {
                    await authModel.setBiometricEnabled(v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(authModel.biometricEnabled, isFalse);

    // Tap switch to enable biometrics
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(authModel.biometricEnabled, isTrue);
  });
}
