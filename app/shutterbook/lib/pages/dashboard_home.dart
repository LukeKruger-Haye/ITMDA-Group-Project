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

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  // Whether horizontal swiping between pages is enabled. Can be toggled
  // programmatically (e.g. to lock navigation while a modal flow runs).
  bool _swipeEnabled = true;
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // No fractional page listener needed when indicator is removed.
    // Initialize FAB animation controller and staggered animations here
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    // create staggered intervals for 4 mini FABs
    _fabSlideAnims = List.generate(4, (i) {
      final start = (i * 0.08).clamp(0.0, 0.9);
      final end = (0.45 + i * 0.1).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _fabController, curve: Interval(start, end, curve: Curves.easeOut)));
    });
    _fabScaleAnims = List.generate(4, (i) {
      final start = (i * 0.08).clamp(0.0, 0.9);
      final end = (0.5 + i * 0.1).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _fabController, curve: Interval(start, end, curve: Curves.easeOutBack)));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Animation controller and staggered animations for the dashboard mini FABs
  late final AnimationController _fabController;
  late final List<Animation<Offset>> _fabSlideAnims;
  late final List<Animation<double>> _fabScaleAnims;

  void _toggleFab() {
    if (_fabController.isDismissed) {
      // animate in
      _fabController.forward();
    } else {
      // animate out
      _fabController.reverse();
    }
  }

  void _closeFab() {
    if (!_fabController.isDismissed) {
      _fabController.reverse();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    // PageView provides native horizontal swipe navigation with animation.
    return PageView(
      controller: _pageController,
      physics: _swipeEnabled ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() {
        _currentIndex = index;
        // close the dashboard FAB when navigating away or between pages
        if (!_fabController.isDismissed) _fabController.reverse();
      }),
      children: [
        // Use the redesigned DashboardPage as the embedded home dashboard
        DashboardPage(
          embedded: true,
          onNavigateToTab: (index) {
            // dashboard can ask to navigate to another tab — animate the page transition
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
        ),
        BookingsPage(key: _bookingsKey, embedded: true),
        ClientsPage(
          key: _clientsKey,
          embedded: true,
          onViewBookings: (client) async {
            // animate to Bookings tab and focus the embedded BookingsPage
            await _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            final state = _bookingsKey.currentState;
            if (state != null) {
              try {
                (state as dynamic).focusOnClient(client);
              } catch (_) {}
            }
          },
          onViewQuotes: (client) async {
            // animate to Quotes tab and tell embedded QuotePage to focus on the client
            await _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            final state = _quotesKey.currentState;
            if (state != null) {
              try {
                (state as dynamic).focusOnClient(client);
              } catch (_) {}
            }
          },
        ),
        QuotePage(key: _quotesKey, embedded: true),
        InventoryPage(key: _inventoryKey, embedded: true),
      ],
    );
  }

  /// Enable or disable swipe navigation. Public so parent widgets or
  /// embedded pages can lock navigation when needed.
  void setSwipeEnabled(bool enabled) {
    if (!mounted) return;
    setState(() => _swipeEnabled = enabled);
  }

  // Page indicator removed per UX feedback.

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 1: // Bookings
      case 0: // Dashboard - show an expanding FAB with quick-create options
        // Use a Column so mini FABs stack above the main FAB. AnimatedSwitcher/AnimatedOpacity
        // provide a smooth transition when toggling.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // mini action buttons (appear when expanded) — slide & scale with stagger
            AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) {
                final show = _fabController.isAnimating || _fabController.value > 0.001;
                if (!show) return const SizedBox.shrink();
                return Opacity(
                  opacity: (_fabController.value).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quote
                      SlideTransition(
                        position: _fabSlideAnims[0],
                        child: ScaleTransition(
                          scale: _fabScaleAnims[0],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_quote',
                              onPressed: () async {
                                _closeFab();
                                final nav = Navigator.of(context);
                               
                                // fallback to full CreateQuote page if embedded not available
                                final created = await nav.push<bool>(MaterialPageRoute(builder: (_) => const CreateQuotePage()));
                                if (created == true) {
                                  final s = _quotesKey.currentState;
                                  if (s != null) {
                                    try {
                                      await (s as dynamic).refresh();
                                    } catch (_) {}
                                  }
                                  if (mounted) setState(() {});
                                }
                              },
                              tooltip: 'Create quote',
                              child: const Icon(Icons.request_quote, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // Booking
                      SlideTransition(
                        position: _fabSlideAnims[1],
                        child: ScaleTransition(
                          scale: _fabScaleAnims[1],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_booking',
                              onPressed: () async {
                                _closeFab();
                                final nav = Navigator.of(context);
                                // switch to Bookings tab and trigger embedded create flow if available
                                await _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                final state = _bookingsKey.currentState;
                                if (state != null) {
                                  try {
                                    await (state as dynamic).openCreateBooking();
                                    return;
                                  } catch (_) {}
                                }
                                // fallback
                                final created = await nav.push<bool>(MaterialPageRoute(builder: (_) => CreateBookingPage()));
                                if (created == true && mounted) setState(() {});
                              },
                              tooltip: 'Create booking',
                              child: const Icon(Icons.calendar_today, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // Client (direct to add page)
                      SlideTransition(
                        position: _fabSlideAnims[2],
                        child: ScaleTransition(
                          scale: _fabScaleAnims[2],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_client',
                              onPressed: () async {
                                _closeFab();
                                final nav = Navigator.of(context);
                                await _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                final state = _clientsKey.currentState;
                                if (state != null) {
                                  try {
                                    await (state as dynamic).openAddDialog();
                                    try {
                                      await (state as dynamic).refresh();
                                    } catch (_) {}
                                    return;
                                  } catch (_) {}
                                }
                                await nav.push<bool>(MaterialPageRoute(builder: (_) => const ClientsPage(embedded: false, openAddOnLoad: true)));
                                if (mounted) setState(() {});
                              },
                              tooltip: 'Add client',
                              child: const Icon(Icons.person_add, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // Inventory (direct to add page)
                      SlideTransition(
                        position: _fabSlideAnims[3],
                        child: ScaleTransition(
                          scale: _fabScaleAnims[3],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_item',
                              onPressed: () async {
                                _closeFab();
                                final nav = Navigator.of(context);
                                await _pageController.animateToPage(4, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                final state = _inventoryKey.currentState;
                                if (state != null) {
                                  try {
                                    await (state as dynamic).openAddDialog();
                                    try {
                                      await (state as dynamic).refresh();
                                    } catch (_) {}
                                    return;
                                  } catch (_) {}
                                }
                                await nav.push<bool>(MaterialPageRoute(builder: (_) => const InventoryPage(embedded: false, openAddOnLoad: true)));
                                if (mounted) setState(() {});
                              },
                              tooltip: 'Add inventory',
                              child: const Icon(Icons.inventory, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
            // main FAB toggles the mini buttons
            FloatingActionButton(
              onPressed: _toggleFab,
              child: AnimatedBuilder(
                animation: _fabController,
                builder: (context, _) {
                  return Icon(_fabController.value > 0.5 ? Icons.close : Icons.add);
                },
              ),
              tooltip: 'Create',
            ),
          ],
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
  final Color activeColor = AppColors.colorForIndex(context, _currentIndex);
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
        onTap: (i) {
          // animate the PageView to the tapped page
          _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
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
