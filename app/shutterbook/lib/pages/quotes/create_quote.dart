import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/client_table.dart';


class CreateQuotePage extends StatefulWidget{
  const CreateQuotePage({super.key});

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  List<Client> allClients = [];
  List<Client> suggestions = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    allClients = await ClientTable().getAllClients();
    setState(() {});
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchText = value;
      suggestions = allClients
          .where((client) =>
              client.firstName.toLowerCase().contains(value.toLowerCase()) ||
              client.lastName.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
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
              decoration: const InputDecoration(
                labelText: 'Search Client',
                border: OutlineInputBorder(),
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
                          suggestions = [];
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