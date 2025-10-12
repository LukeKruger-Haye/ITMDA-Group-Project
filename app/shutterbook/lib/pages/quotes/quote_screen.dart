
import 'package:flutter/material.dart';


class QuotePage extends StatelessWidget{
const QuotePage({super.key}); 
  
  @override
  Widget build(BuildContext context) {
    // NOTE: QuoteScreen returns a Scaffold (not a MaterialApp) because MaterialApp
    // is already the root in main().
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Quotes'),
      ),
        body:const Buttons()
        

      );
    
    
  }
}

class Buttons extends StatefulWidget{
  const Buttons({super.key});

@override
  State createState() => ButtonsState();
}

class ButtonsState extends State<Buttons>{
  void onPressedCreate(){
    Navigator.pushNamed(context, '/quotes/create_quote.dart');
  }

  void onPressedManage(){
    Navigator.pushNamed(context, '/quotes/manage_quote.dart');
  }


  @override
  Widget build(BuildContext context){
    final ButtonStyle style = ElevatedButton.styleFrom(textStyle : const TextStyle(fontSize: 30));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(style:style, onPressed: onPressedCreate, child: const Text("Create")),
        const SizedBox(height :60),
        ElevatedButton(style:style, onPressed: onPressedManage, child: const Text("Manage"))
      ],
      ),
    );
  
  }

}
