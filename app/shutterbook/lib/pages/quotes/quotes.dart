import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/models/quote.dart';
import '../../data/tables/quote_table.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  Client? _client;
  bool _loading = false;
  List<Quote> _quotes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Client) {
      // Load quotes for this client
      _client = args;
      _loadQuotesForClient();
    }
  }

  Future<void> _loadQuotesForClient() async {
    if (_client == null || _client!.id == null) return;
    setState(() {
      _loading = true;
    });
    final data = await QuoteTable().getQuotesByClient(_client!.id!);
    if (!mounted) return;
    setState(() {
      _quotes = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_client != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quotes — ${_client!.firstName} ${_client!.lastName}'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _quotes.isEmpty
                ? const Center(child: Text('No quotes for this client'))
                : ListView.separated(
                    itemCount: _quotes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final q = _quotes[index];
                      final title = 'Quote #${q.id}';
                      final subtitle = 'Total: ${q.totalPrice} • ${q.createdAt ?? ''}';
                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(title),
                        subtitle: Text(
                          '${q.description}\n$subtitle',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Open manage quote screen for that quote
                          Navigator.pushNamed(context, '/quotes/manage/manage_quote_screen.dart', arguments: q);
                        },
                      );
                    },
                  ),
      );
    }

    // Default non-client view — simple buttons to create/manage quotes
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Quotes'),
      ),
      body: const Buttons(),
    );
  }
}

class Buttons extends StatefulWidget {
  const Buttons({super.key});

  @override
  State createState() => ButtonsState();
}

class ButtonsState extends State<Buttons> {
  void onPressedCreate() {
    Navigator.pushNamed(context, '/quotes/create/create_quote.dart');
  }

  void onPressedManage() {
    Navigator.pushNamed(context, '/quotes/manage/manage_quote_screen.dart');
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 30));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(style: style, onPressed: onPressedCreate, child: const Text("Create")),
          const SizedBox(height: 60),
          ElevatedButton(style: style, onPressed: onPressedManage, child: const Text("Manage"))
        ],
      ),
    );
  }
}
