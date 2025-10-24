import 'package:flutter/material.dart';
import 'package:shutterbook/pages/quotes/overview/quote_overview_screen.dart';
import '../../data/models/client.dart';
import '../../data/models/quote.dart';
import '../../data/models/package.dart';
import '../../utils/formatters.dart';
import '../../data/tables/quote_table.dart';
import '../../data/tables/client_table.dart';
import '../../widgets/section_card.dart';
import '../bookings/create_booking.dart';
import '../../widgets/client_search_dialog.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_picker/package_picker_screen.dart';
import 'manage/manage_quote_screen.dart';

class QuotePage extends StatefulWidget {
  final bool embedded;
  const QuotePage({super.key, this.embedded = false});

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
    final clientBody = _loading
        ? const Center(child: CircularProgressIndicator())
        : _quotes.isEmpty
            ? const Center(child: Text('No quotes for this client'))
            : ListView.separated(
                itemCount: _quotes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final q = _quotes[index];
                  final title = 'Quote #${q.id}';
                  final subtitle = 'Total: ${formatRand(q.totalPrice)} • ${q.createdAt ?? ''}';
                  return SectionCard(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(title),
                      subtitle: Text(
                        '${q.description}\n$subtitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // Open manage quote screen for that quote
                        Navigator.pushNamed(
                          context,
                          '/quotes/manage',
                          arguments: q,
                        );
                      },
                    ),
                  );
                },
              );

    if (_client != null) {
      return widget.embedded
          ? clientBody
          : Scaffold(
              appBar: AppBar(
                title: Text('Quotes — ${_client!.firstName} ${_client!.lastName}'),
              ),
              body: clientBody,
            );
    }

    // Default non-client view — show a list of quotes with actions
  return widget.embedded
    ? QuoteList()
    : Scaffold(
            appBar: AppBar(
              title: const Text('Quotes'),
            ),
            body: QuoteList(),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                // Start guided create flow: pick client -> package -> overview
                final nav = Navigator.of(context);
                final client = await showDialog<Client?>(context: context, builder: (_) => const ClientSearchDialog());
                if (!mounted) return;
                if (client == null) return;
                final packages = await nav.push<dynamic>(
                  MaterialPageRoute(builder: (_) => PackagePickerScreen(client: client)),
                );
                if (!mounted) return;
                if (packages == null) return;
                // calculate total safely
                double total = 0.0;
                if (packages is Map) {
                  for (final entry in packages.entries) {
                    final key = entry.key;
                    final val = entry.value;
                    double price = 0.0;
                    if (key is Package) {
                      price = key.price;
                    } else if (key is Map && key['price'] != null) {
                      price = (key['price'] as num).toDouble();
                    }
                    final int qty = val is int ? val : int.tryParse(val.toString()) ?? 0;
                    total += price * qty;
                  }
                }
                final saved = await nav.push<bool?>(
                  MaterialPageRoute(
                    builder: (_) => QuoteOverviewScreen(
                      client: client,
                      total: total,
                      packages: packages),
                  ),
                );
                if (saved == true && mounted) setState(() {});
              },
              tooltip: 'Create quote',
              child: const Icon(Icons.add),
            ),
          );
  }
}

class QuoteList extends StatefulWidget {
  const QuoteList({super.key});

  @override
  State<QuoteList> createState() => _QuoteListState();
}

class _QuoteListState extends State<QuoteList> {
  final QuoteTable _table = QuoteTable();
  final ClientTable _clientTable = ClientTable();
  List<Quote> _quotes = [];
  bool _loading = true;
  String _filter = '';
  final Map<int, String> _clientNames = {};

  @override
  void initState() {
    super.initState();
    _load(); // Load quotes immediately when widget is created
  }

  @override 
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reload when returning to this screen
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _table.getAllQuotes();
    if (!mounted) return;
    // also preload client names to avoid many DB calls
    try {
      final clients = await _clientTable.getAllClients();
      _clientNames.clear();
      for (final c in clients) {
        if (c.id != null) _clientNames[c.id!] = '${c.firstName} ${c.lastName}';
      }
    } catch (_) {}
    setState(() {
      _quotes = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? _quotes
        : _quotes.where((q) => ('Quote #${q.id}'.toLowerCase()).contains(_filter.toLowerCase()) || q.description.toLowerCase().contains(_filter.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search quotes by id or description', border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _filter = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No quotes'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final q = filtered[index];
                          final clientName = _clientNames[q.clientId] ?? 'Client ${q.clientId}';
                          final title = 'Quote #${q.id} — $clientName';
                          final subtitle = 'Total: ${formatRand(q.totalPrice)} • ${q.createdAt ?? ''}';
                          return SectionCard(
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(title),
                              subtitle: Text(
                                '${q.description}\n$subtitle',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: 'Book from quote',
                                  onPressed: () async {
                                      final nav = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        final created = await nav.push<bool>(
                                          MaterialPageRoute(builder: (_) => CreateBookingPage(quote: q)),
                                        );
                                        if (created == true) {
                                          if (mounted) await _load();
                                        }
                                      } catch (e) {
                                        messenger.showSnackBar(SnackBar(content: Text('Failed to book: $e')));
                                      }
                                    },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  tooltip: 'View',
                                  onPressed: () async {
                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await nav.push(
                                        MaterialPageRoute(builder: (_) => const ManageQuotePage(), settings: RouteSettings(arguments: q)),
                                      );
                                      if (mounted) {
                                        await _load();
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(SnackBar(content: Text('Failed to open quote: $e')));
                                    }
                                  },
                                ),
                              ]),
                              onTap: () async {
                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await nav.push(
                                    MaterialPageRoute(builder: (_) => const ManageQuotePage(), settings: RouteSettings(arguments: q)),
                                  );
                                  if (mounted) {
                                    await _load();
                                  }
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Failed to open quote: $e')));
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
