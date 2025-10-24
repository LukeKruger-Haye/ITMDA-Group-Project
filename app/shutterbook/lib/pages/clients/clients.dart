import 'dart:async';
import 'package:flutter/foundation.dart';
// Shutterbook — Clients management
// Lists and edits clients. Keep UI logic here; persistence is in
// `data/tables/client_table.dart`.
import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/tables/client_table.dart';
import '../../data/tables/quote_table.dart';
import '../../data/tables/booking_table.dart';
import '../theme_controller.dart'; // added to react to global theme
import '../../theme/app_colors.dart';
import '../../widgets/section_card.dart';
import '../bookings/bookings.dart';

class ClientsPage extends StatefulWidget {
  final bool embedded; // when true, return content only (no Scaffold)
  final void Function(Client client)? onViewBookings;
  final void Function(Client client)? onViewQuotes;
  const ClientsPage({super.key, this.embedded = false, this.onViewBookings, this.onViewQuotes});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientTable _clientTable = ClientTable();
  final QuoteTable _quoteTable = QuoteTable();
  final BookingTable _bookingTable = BookingTable();

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadClients() async {
    final clients = await _clientTable.getAllClients();
    setState(() {
      _clients = clients;
      // Apply current search filter (if any) after loading
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      _filteredClients = _clients.where((c) {
        final full = '${c.firstName} ${c.lastName}'.toLowerCase();
        return full.contains(q) || c.email.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || '${c.id}'.contains(q);
      }).toList();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _applyFilter();
      });
    });
  }

  // Public refresh method so parent (DashboardHome) can trigger reload when embedded
  Future<void> refresh() async => _loadClients();

  // Publicly callable method to open the Add Client dialog when embedded
  Future<void> openAddDialog() async => await _addOrEditClient();

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Invalid email format';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone required';
    final phoneRegex = RegExp(r'^\d{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Phone must be 7-15 digits';
    }
    return null;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final nav = Navigator.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => nav.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => nav.pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addOrEditClient({Client? client}) async {
    final firstNameController = TextEditingController(
      text: client?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: client?.lastName ?? '',
    );
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Add Client' : 'Edit Client'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'First name required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Last name required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              if (formKey.currentState?.validate() ?? false) {
                final confirmed = await _showConfirmationDialog(
                  client == null ? 'Add Client' : 'Save Changes',
                  client == null
                      ? 'Are you sure you want to add this client?'
                      : 'Are you sure you want to save changes to this client?',
                );
                if (!confirmed) return;
                final newClient = Client(
                  id: client?.id,
                  firstName: _capitalize(firstNameController.text.trim()),
                  lastName: _capitalize(lastNameController.text.trim()),
                  email: emailController.text.trim().toLowerCase(),
                  phone: phoneController.text.trim().replaceAll(
                    RegExp(r'\D'),
                    '',
                  ),
                );
                if (nav.mounted) nav.pop(newClient);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (client == null) {
        await _clientTable.insertClient(result);
      } else {
        await _clientTable.updateClient(result);
      }
      _loadClients();
    }
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Client',
      'Are you sure you want to delete ${client.firstName} ${client.lastName}?',
    );
    if (confirmed && client.id != null) {
      await _clientTable.deleteClient(client.id!);
      _loadClients();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // show client details dialog with actions to view quotes or bookings (shows counts)
  Future<void> _showClientDetails(Client client) async {
    int quotesCount = 0;
    int bookingsCount = 0;

    if (client.id != null) {
      try {
        final quotes = await _quoteTable.getQuotesByClient(client.id!);
        final bookings = await _bookingTable.getBookingsByClient(client.id!);
        quotesCount = quotes.length;
        bookingsCount = bookings.length;
      } catch (e) {
        if (kDebugMode) debugPrint('Error fetching client counts: $e');
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${client.firstName} ${client.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${client.email}'),
            const SizedBox(height: 8),
            Text('Phone: ${client.phone}'),
            const SizedBox(height: 12),
            Text('Quotes: $quotesCount'),
            const SizedBox(height: 6),
            Text('Bookings: $bookingsCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              final nav = Navigator.of(context);
              nav.pop();
              // Delegate to parent's onViewQuotes if available so we don't push separate views
              if (widget.onViewQuotes != null) {
                try {
                  widget.onViewQuotes!(client);
                  return;
                } catch (_) {}
              }
              // fallback to opening full Quotes page
              Navigator.pushNamed(nav.context, '/quotes', arguments: client);
            },
            child: const Text('View Quotes'),
          ),
          ElevatedButton(
            onPressed: () {
              final nav = Navigator.of(context);
              nav.pop();
              // Delegate to parent's onViewBookings if available so we don't push separate views
              if (widget.onViewBookings != null) {
                try {
                  widget.onViewBookings!(client);
                } catch (_) {
                  // fallback to opening full Bookings page
                  Navigator.push(nav.context, MaterialPageRoute(builder: (_) => BookingsPage(initialClient: client)));
                }
              } else {
                Navigator.push(nav.context, MaterialPageRoute(builder: (_) => BookingsPage(initialClient: client)));
              }
            },
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the page's Scaffold with a Theme that follows ThemeController so this page shows dark/light
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (context, isDark, _) {
        final pageTheme = isDark ? ThemeData.dark() : ThemeData.light();
        final pageBody = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                        : null,
                    hintText: 'Search clients by name, email or phone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredClients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final client = _filteredClients[index];
              return SectionCard(
                child: ListTile(
                  onTap: () => _showClientDetails(client),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()),
                    child: Text(
                      client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  title: Text('${client.firstName} ${client.lastName}'),
                  subtitle: Text('${client.email} • ${client.phone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditClient(client: client),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteClient(client),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
                ),
              ),
            ],
          ),
        );

        return Theme(
          data: pageTheme,
          child: widget.embedded
              ? pageBody
              : Scaffold(
                        appBar: AppBar(
                          title: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.colorForIndex(2).withAlpha((0.95 * 255).round()),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Text('Clients'),
                            ],
                          ),
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(2.0),
                            child: Container(height: 2.0, color: AppColors.colorForIndex(2).withAlpha((0.6 * 255).round())),
                          ),
                        ),
                        body: pageBody,
                        floatingActionButton: FloatingActionButton(
                          onPressed: () => _addOrEditClient(),
                          tooltip: 'Add Client',
                          child: const Icon(Icons.person_add),
                        ),
                      ),
        );
      },
    );
  }
}
