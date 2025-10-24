import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

import 'package:shutterbook/data/models/package.dart';



class QuoteOverviewEditScreen extends StatelessWidget {
final int quoteNum;
final String clientName;
final double total;


final Map<Package, int> packages;

  const QuoteOverviewEditScreen({super.key, required this.total, required this.packages, required this.quoteNum, required this.clientName});


  Future<void> _updateQuote() async
  {
     final String packageDescription = packages.entries
         .map((entry) => '${entry.key.name} x${entry.value}')
         .join(', ');


     final quoteInfo = await QuoteTable().getQuoteById(quoteNum);
     int clientInfoId = 0;

     if (quoteInfo != null) {
       // quoteInfo is a single Quote, not an iterable; extract clientId directly.
       clientInfoId = quoteInfo.clientId;
     }

    

    final quote = Quote(
      id: quoteNum,
      clientId: clientInfoId,
      totalPrice: total,
      description: packageDescription,
    );
    final table = QuoteTable();
    await table.updateQuote(quote);

    debugPrint('Updated quote:${quote.toMap()}');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Overview')),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quote #$quoteNum\n$clientName\nTotal: R${total.toStringAsFixed(2)}'),            
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map((entry) => Text('${entry.key.name} x${entry.value} - R${(entry.key.price * entry.value).toStringAsFixed(2)}')),
           const SizedBox(height: 30,),
           ElevatedButton(onPressed: (){
             
             _updateQuote();
             Navigator.pushNamedAndRemoveUntil(context, '/quotes', (route) => false);     
             
             
                      
           }, child: const Text("Update")),
           const SizedBox(height: 10),
           ElevatedButton(onPressed: (){

             Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);     


           }, child: const Text("Cancel"))

          ],
        ),
      ),
    );
  }
}