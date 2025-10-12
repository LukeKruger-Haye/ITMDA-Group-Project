import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/client_table.dart';


class CreateQuotePage extends StatefulWidget{
  const CreateQuotePage({super.key});

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  @override
  void initState() {
    super.initState();
    _insertClients();
  }

  Future<void> _insertClients() async {
    final clients =[
    Client(
      id : 1,
      firstName: 'James',
      lastName: 'Baxtor',
      email: 'james.baxtor@example.com',
      phone: '555-123-4567',
    ),
      Client(
      id : 2,
      firstName: 'Mary',
      lastName: 'Jane',
      email: 'mary.jane@example.com',
      phone: '654-321-7654',
    ),
    ];
    for (var client in clients) {
      await ClientTable().insertClient(client);
    }
    final fetchedClient = await ClientTable().getAllClients();
    
    for (var client in fetchedClient) {
      debugPrint('Id: ${client.id}, Client: ${client.firstName} ${client.lastName}, Email: ${client.email}, Phone: ${client.phone}');
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quote'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please search client'),
            SizedBox(height: 20),
            SearchBar(
              hintText: 'Search Client',
              onTap: null,

            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: null, // Implement search functionality
              child: Text('Confirm Client'),
            ),
          ],
        ),
      ),
    );
  }
}