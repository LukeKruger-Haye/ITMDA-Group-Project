
import 'package:flutter/material.dart';



class QuotePage extends StatefulWidget {
const QuotePage({super.key});

@override
State createState() => QuotePageState();

}


class QuotePageState extends State<QuotePage> {


  @override
  Widget build(BuildContext context) {
    // NOTE: QuoteScreen returns a Scaffold (not a MaterialApp) because MaterialApp
    // is already the root in main().
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Quote Generator'),
        ),
      );
    
    
  }
}
