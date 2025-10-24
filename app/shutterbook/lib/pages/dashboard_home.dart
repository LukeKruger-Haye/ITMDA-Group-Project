// ignore_for_file: sort_child_properties_last
import 'package:flutter/material.dart';
import 'authentication/models/auth_model.dart';
// dashboard page temporarily removed - using placeholder while redesigning
import 'bookings/dashboard.dart';
import 'bookings/bookings.dart';
import 'clients/clients.dart';
import 'quotes/quotes.dart';
import 'quotes/create/create_quote.dart';
import 'bookings/create_booking.dart';
import 'inventory/inventory.dart';
import 'settings/settings.dart';

class DashboardHome extends StatefulWidget {
  final AuthModel authModel;

  const DashboardHome({super.key, required this.authModel});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _currentIndex = 0;
  final GlobalKey _clientsKey = GlobalKey();
  final GlobalKey _bookingsKey = GlobalKey();
  final GlobalKey _inventoryKey = GlobalKey();

  static const _labels = [
    'Dashboard',
    'Bookings',
    'Clients',
    'Quotes',
    'Inventory',
  ];

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // Use the redesigned DashboardPage as the embedded home dashboard
        DashboardPage(
          embedded: true,
          onNavigateToTab: (index) => setState(() => _currentIndex = index),
        ),
        BookingsPage(key: _bookingsKey, embedded: true),
        ClientsPage(key: _clientsKey, embedded: true, onViewBookings: (client) {
          // when a client requests to view bookings, switch to Bookings tab and focus the embedded BookingsPage
          setState(() {
            _currentIndex = 1;
          });
          // try to call focusOnClient on the embedded bookings page
          final state = _bookingsKey.currentState;
          if (state != null) {
            try {
              (state as dynamic).focusOnClient(client);
            } catch (_) {}
          }
        }),
        const QuotePage(embedded: true),
        InventoryPage(key: _inventoryKey, embedded: true),
      ],
    );
  }

  FloatingActionButton? _buildFab() {
    switch (_currentIndex) {
      case 1: // Bookings
      case 0: // Dashboard - convenient to create bookings
        return FloatingActionButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            final created = await nav.push<bool>(
              MaterialPageRoute(builder: (_) => CreateBookingPage()),
            );
            if (created == true && mounted) setState(() {});
          },
          child: const Icon(Icons.add),
          tooltip: 'Create booking',
        );
      case 3: // Quotes
        return FloatingActionButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            final created = await nav.push<bool>(
              MaterialPageRoute(builder: (_) => CreateQuotePage()),
            );
            if (created == true && mounted) setState(() {});
          },
          child: const Icon(Icons.request_quote),
          tooltip: 'Create ',
        );
      case 2: // Clients - open add client dialog by delegating to page
        return FloatingActionButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            // Try to call the embedded page's openAddDialog() if present (keeps user on dashboard)
            final state = _clientsKey.currentState;
            if (state != null) {
              try {
                await (state as dynamic).openAddDialog();
                // refresh embedded page after add
                try {
                  await (state as dynamic).refresh();
                } catch (_) {}
              } catch (_) {
                // fallback to opening full Clients page
                await nav.push<bool>(MaterialPageRoute(builder: (_) => const ClientsPage(embedded: false)));
              }
            } else {
              await nav.push<bool>(MaterialPageRoute(builder: (_) => const ClientsPage(embedded: false)));
            }
            if (mounted) setState(() {});
          },
          child: const Icon(Icons.person_add),
          tooltip: 'Add client',
        );
      case 4: // Inventory
        return FloatingActionButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            final state = _inventoryKey.currentState;
            if (state != null) {
              try {
                await (state as dynamic).openAddDialog();
                try {
                  await (state as dynamic).refresh();
                } catch (_) {}
              } catch (_) {
                await nav.push<bool>(MaterialPageRoute(builder: (_) => const InventoryPage(embedded: false)));
              }
            } else {
              await nav.push<bool>(MaterialPageRoute(builder: (_) => const InventoryPage(embedded: false)));
            }
            if (mounted) setState(() {});
          },
          child: const Icon(Icons.add),
          tooltip: 'Add inventory',
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(authModel: widget.authModel),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.request_quote), label: 'Quotes'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
        ],
      ),
    );
  }
}
