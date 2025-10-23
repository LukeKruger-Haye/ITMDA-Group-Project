import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

import 'package:shutterbook/data/models/package.dart';



class QuoteOverviewEditScreen extends StatelessWidget {
final int quoteNum;
final double total;
final Client client;
final Map<Package, int> packages;

  const QuoteOverviewEditScreen({super.key, required this.client, required this.total, required this.packages, required this.quoteNum});


  Future<void> _updateQuote() async
  {
    final String packageDescription = packages.entries
        .map((entry) => '${entry.key.name} x${entry.value}')
        .join(', ');

    final table = QuoteTable();

    final quote = Quote(
      id: quoteNum,
      clientId: client.id!,
      totalPrice: total,
      description: packageDescription,
    );

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
            Text('Client: ${client.id} ${client.firstName} ${client.lastName}'),
            Text('Total: R${total.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map((entry) => Text('${entry.key.name} x${entry.value} - R${(entry.key.price * entry.value).toStringAsFixed(2)}')),
           const SizedBox(height: 30,),
           ElevatedButton(onPressed: (){
             
             _updateQuote();
             Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);     
             
             
                      
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