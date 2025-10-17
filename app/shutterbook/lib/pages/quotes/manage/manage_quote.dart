

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
TextEditingController myEditor= TextEditingController();
String searchText='';

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

// Future <void> _deleteQuote() async{

// }

}

@override
Widget build(BuildContext context){
  return Column(
    children: [
      TextField(
         controller: myEditor,
              decoration: InputDecoration(
                labelText: 'Search Client',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: (){},
                   icon: const Icon(Icons.search),
                   tooltip: 'Search',
                   )

                 

                ],
              )
              ),
                
      ),
      const SizedBox(height: 9),

      Expanded(

        child: ListView.builder(
          itemCount: allQuotes.length,
          itemBuilder:(context, index){
            final quote=allQuotes[index];
            
            return ListTile(
              title: Text('Quote #${quote.id}'),
              subtitle: Text('Client name:${quote.clientId} \t ${quote.createdAt}\n R${quote.totalPrice}' ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                        tooltip: 'Edit',
                  ),

                  IconButton(onPressed: (){},
                   icon: const Icon(Icons.delete),
                   tooltip: 'Delete',
                   )

                ],



              ),
              onTap: () {
                
              },
            );
            
          } ),
          
      ),
    ],
  );
}

}