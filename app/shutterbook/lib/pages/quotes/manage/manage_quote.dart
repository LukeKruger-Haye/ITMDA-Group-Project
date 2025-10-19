import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

class ManageQuote extends StatefulWidget {
  const ManageQuote({super.key});

  @override
  ManageQuoteState createState() => ManageQuoteState();
}

class ManageQuoteState extends State<ManageQuote> {
  List<Quote> allQuotes = [];
  List<Quote> filteredQuotes = [];

  TextEditingController myEditor = TextEditingController();
  String searchText = '';

  bool _loading = true;

  // map quote_id -> Client
  final Map<int, Client?> _clientForQuote = {};

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _loading = true;
      
    });
    final quoteData = await QuoteTable().getAllQuotes();

    

    // set initial lists
    setState(() {
      allQuotes = quoteData;
      filteredQuotes = List<Quote>.from(quoteData);
    });

    // fetch client for each quote (uses the join query you already have)
    final clientTable = ClientTable();
    final Map<int, Client?> clientMap = {};
    for (final q in quoteData) {
      if (q.id != null) {
        clientMap[q.id!] = await clientTable.getClientByQuoteId(q.id!);
      }
    }

    setState(() {
      _clientForQuote.clear();
      _clientForQuote.addAll(clientMap);
      _loading = false;
    });

    // If user already typed something, re-apply filter
    if (myEditor.text.isNotEmpty) {
      _filterQuotes(myEditor.text);
    }
  }

  void _filterQuotes(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      searchText = value;
      if (q.isEmpty) {
        filteredQuotes = List<Quote>.from(allQuotes);
        return;
      }

      filteredQuotes = allQuotes.where((quote) {
        final client = (quote.id != null) ? _clientForQuote[quote.id!] : null;

        // build searchable strings
        final clientFull = client != null
            ? '${client.firstName} ${client.lastName}'.toLowerCase()
            : '';
        final first = client?.firstName.toLowerCase() ?? '';
        final last = client?.lastName.toLowerCase() ?? '';
        final clientIdStr = quote.clientId.toString();
        final quoteIdStr = (quote.id != null) ? quote.id.toString() : '';

        return clientFull.contains(q) ||
            first.contains(q) ||
            last.contains(q) ||
            clientIdStr.contains(q) ||
            quoteIdStr.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    myEditor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                IconButton(
                  onPressed: () => _filterQuotes(myEditor.text),
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                if (myEditor.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      myEditor.clear();
                      _filterQuotes('');
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear',
                  ),
              ],
            ),
          ),
          onChanged: _filterQuotes,
        ),
        const SizedBox(height: 9),
        Expanded(
          child: filteredQuotes.isEmpty
              ? const Center(child: Text('No quotes found'))
              : ListView.builder(
                  itemCount: filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = filteredQuotes[index];

                    // lookup client by the quote's id (we store by quote.id)
                    final client =
                        (quote.id != null) ? _clientForQuote[quote.id!] : null;
                    final clientName = client != null
                        ? '${client.firstName} ${client.lastName}'
                        : 'Client #${quote.clientId} (not found)';

                    final created =
                        quote.createdAt != null ? quote.createdAt.toString() : '';

                    return ListTile(
                      title: Text('Quote #${quote.id ?? index}'),
                      subtitle: Text(
                          'Client: $clientName\n$created\nR${quote.totalPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {},
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete',
                          )
                        ],
                      ),
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }
}