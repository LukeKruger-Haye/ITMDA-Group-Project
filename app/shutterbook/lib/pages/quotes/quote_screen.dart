// Shutterbook — Quote detail screen
// Displays details for a single quote and provides actions like booking
// or editing.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class QuotePage extends StatelessWidget {
  const QuotePage({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: QuoteScreen returns a Scaffold (not a MaterialApp) because MaterialApp
    // is already the root in main().

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Quotes'),
      ),
      body: const Buttons(),
    );
  }
}

class Buttons extends StatefulWidget {
  const Buttons({super.key});

  @override
  State createState() => ButtonsState();
}

class ButtonsState extends State<Buttons> {
  void onPressedCreate() {
    Navigator.pushNamed(context, '/quotes/create');
  }

  void onPressedManage() {
    Navigator.pushNamed(context, '/quotes/manage');
  }

  @override
  Widget build(BuildContext context) {
    // Use centralized UI styles for consistency
    final ButtonStyle style = UIStyles.primaryButton(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: style,
            onPressed: onPressedCreate,
            child: const Text("Create", style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            style: style,
            onPressed: onPressedManage,
            child: const Text("Manage", style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}
