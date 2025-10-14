import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/pages/quotes/create/package_picker_screen.dart';




class CreateQuotePage extends StatefulWidget{
  const CreateQuotePage({super.key});

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {  
  List<Client> allClients = [];
  List<Client> suggestions = [];
  String searchText = '';

  final TextEditingController myEditor=TextEditingController();
  bool showIcon=false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {

    final table = ClientTable();
    final james = Client(id: 1, firstName: 'James', lastName: 'Baxtor', email: 'james.baxtor@example.com', phone: '123-456-7890');
    final mary =Client(id:2 ,firstName: 'Mary', lastName: 'Jane', email: 'mary.jane@example.com', phone: '987-654-3210');
    await table.insertClient(james);
    await table.insertClient(mary);

    debugPrint('${james.toMap()} \n ${mary.toMap()}');

    final data = await table.getAllClients();
    setState(() {
      allClients = data;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchText = value;
      suggestions = allClients
      .where((client) =>
        client.firstName.toLowerCase().contains(value.toLowerCase()) ||
        client.lastName.toLowerCase().contains(value.toLowerCase()))
      .toList();
      if (suggestions.isEmpty)
      {
        showIcon=false;
      }
    });
  }

  void _onTapChange(String searchText)
  {
   myEditor.text=searchText;
   if (myEditor.text == searchText)
   {
    showIcon=true;
   }
   

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quote'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: myEditor,
              decoration: InputDecoration(
                labelText: 'Search Client',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if(showIcon)
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context)=> PackagePickerScreen()));
                          // Add your onPressed logic here
                        },
                      ),
                    if(myEditor.text.isNotEmpty || showIcon)  
                    IconButton(
                      onPressed: () {
                        myEditor.text = "";
                        setState(() {
                          showIcon=false;
                        });
                  
                        
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            if (searchText.isNotEmpty && suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final client = suggestions[index];
                  return ListTile(
                    title: Text('${client.firstName} ${client.lastName}'),
                    subtitle: Text(client.email),
                    onTap: () {
                      // Handle client selection
                      debugPrint('Selected: ${client.firstName} ${client.lastName}');
                      setState(() {
                        searchText = '${client.firstName} ${client.lastName}';
                        _onTapChange(searchText);
                        suggestions = [client];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
