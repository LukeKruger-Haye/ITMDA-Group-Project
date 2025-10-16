

import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';


class ManageQuote  extends StatefulWidget{
  const ManageQuote({super.key});

@override
  ManageQuoteState createState() => ManageQuoteState();
}

 



class ManageQuoteState extends State<ManageQuote>{

List <Quote> allQuotes=[];
List <Quote> quotesearchSuggestions=[];


 @override 
void initState(){
  super.initState();
  _loadQuotes();
}

Future <void> _loadQuotes() async{


final quoteData= await QuoteTable().getAllQuotes();

setState(() {
  allQuotes=quoteData;
});


}

@override
Widget build(BuildContext context){
  return Column(
    children: [
      TextField(
                
      ),
      const SizedBox(height: 30,),
      ListView.builder(
        itemBuilder:(context, index){
          final quote=allQuotes[index];
          
          return ListTile(
            title: Text('Quote # ${quote.id}'),
            subtitle: Text('Client id:${quote.clientId} \t ${quote.createdAt}\t ${quote.totalPrice}' ),
          );
          
        } ),
    ],
  );
}

}