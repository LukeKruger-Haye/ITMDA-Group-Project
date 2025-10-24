// Shutterbook — Dashboard home
// The embedded-tab dashboard used as the app's landing page. Hosts
// Bookings, Clients, Quotes and Inventory tabs and exposes quick actions.
// Keep tab-switching logic here for a compact UX.
// ignore_for_file: sort_child_properties_last
import 'package:flutter/material.dart';
import 'authentication/models/auth_model.dart';
import 'bookings/dashboard.dart';
import 'bookings/bookings.dart';
import 'clients/clients.dart';
import 'quotes/quotes.dart';
import 'quotes/create/create_quote.dart';
import 'bookings/create_booking.dart';
import 'inventory/inventory.dart';
import 'settings/settings.dart';
import '../theme/app_colors.dart';

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
  // key for the embedded quotes page so we can trigger a refresh after creates
  final GlobalKey _quotesKey = GlobalKey();

  // Use centralized colors from AppColors

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
        ClientsPage(
          key: _clientsKey,
          embedded: true,
          onViewBookings: (client) {
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
          },
          onViewQuotes: (client) {
            // switch to Quotes tab and tell embedded QuotePage to focus on the client
            setState(() {
              _currentIndex = 3;
            });
            final state = _quotesKey.currentState;
            if (state != null) {
              try {
                (state as dynamic).focusOnClient(client);
              } catch (_) {}
            }
        }),
        QuotePage(key: _quotesKey, embedded: true),
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
            if (created == true) {
              // try to notify the embedded quotes page to refresh its data
              final state = _quotesKey.currentState;
              if (state != null) {
                try {
                  await (state as dynamic).refresh();
                } catch (_) {}
              }
              if (mounted) setState(() {});
            }
          },
          child: const Icon(Icons.request_quote),
          tooltip: 'Create quote',
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
  final Color activeColor = AppColors.colorForIndex(_currentIndex);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // small left color accent
            Container(
              width: 6,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                color: activeColor.withAlpha((0.95 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(_labels[_currentIndex]),
          ],
        ),
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
         // subtle colored underline to indicate active tab without changing
         // the AppBar's main color — animate the color change for polish.
         bottom: PreferredSize(
           preferredSize: const Size.fromHeight(3.0),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: 3.0,
            color: activeColor.withAlpha((0.6 * 255).round()),
          ),
         ),
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
