import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/tables/client_table.dart';
import '../../data/tables/quote_table.dart';
import '../../data/tables/booking_table.dart';
import '../bookings/client_bookings.dart'; // <-- new import

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientTable _clientTable = ClientTable();
  final QuoteTable _quoteTable = QuoteTable();
  final BookingTable _bookingTable = BookingTable();

  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await _clientTable.getAllClients();
    setState(() {
      _clients = clients;
    });
  }

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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addOrEditClient({Client? client}) async {
    final firstNameController = TextEditingController(text: client?.firstName ?? '');
    final lastNameController = TextEditingController(text: client?.lastName ?? '');
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
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'First name required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Last name required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
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
                  phone: phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
                );
                Navigator.pop(context, newClient);
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
        debugPrint('Error fetching client counts: $e');
      }
    }

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
              Navigator.pop(context);
              Navigator.pushNamed(context, '/quotes', arguments: client);
            },
            child: const Text('View Quotes'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // open the client bookings list page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientBookingsPage(client: client),
                ),
              );
            },
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: ListView.builder(
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index];
          return ListTile(
            onTap: () => _showClientDetails(client),
            title: Text('${client.firstName} ${client.lastName}'),
            subtitle: Text('${client.email} | ${client.phone}'),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditClient(),
        child: const Icon(Icons.add),
        tooltip: 'Add Client',
      ),
    );
  }
}