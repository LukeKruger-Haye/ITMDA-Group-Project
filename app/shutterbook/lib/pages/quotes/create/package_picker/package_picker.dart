import 'package:flutter/foundation.dart';
// Shutterbook — Package picker
// Small helper screen that allows selecting pre-defined packages when
// building a quote.
import 'package:flutter/material.dart';
import 'package:shutterbook/utils/formatters.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/data/models/client.dart';


// Simple Package model
class Package {
  final String name;
  final double price;

  Package({required this.name, required this.price});
}

class PackagePicker extends StatefulWidget {
  final Function(Map<Package, int>) onSelectionChanged;
  final Client client;

  const PackagePicker({
    super.key,
    required this.onSelectionChanged,
    required this.client,
  });

  @override
  PackagePickerState createState() => PackagePickerState();
}

class PackagePickerState extends State<PackagePicker> {
  // Hardcoded package list
  final List<Package> _packages = [
    Package(name: 'Birthday', price: 250.0),
    Package(name: 'Wedding', price: 100.0),
    Package(name: 'Anniversary', price: 250.0),
    Package(name: 'Family', price: 300.0),
  ];

  // Map to track selected packages and their quantities
  final Map<Package, int> _selectedPackages = {};

  void _toggleSelection(Package package) {
    setState(() {
      if (_selectedPackages.containsKey(package)) {
        _selectedPackages.remove(package);
      } else {
        _selectedPackages[package] = 1;
      }
    });
    widget.onSelectionChanged(_selectedPackages);
  }

  void _updateQuantity(Package package, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedPackages[package] = quantity;
      } else {
        _selectedPackages.remove(package);
      }
    });
    widget.onSelectionChanged(_selectedPackages);
  }

  int get totalItems =>
      _selectedPackages.values.fold(0, (sum, qty) => sum + qty);
  double get totalPrice => _selectedPackages.entries.fold(
    0,
    (sum, entry) => sum + entry.key.price * entry.value,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text('${widget.client.firstName} ${widget.client.lastName}'),
        ),
        const Text(
          'Pick Packages:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              final isSelected = _selectedPackages.containsKey(package);
              final quantity = _selectedPackages[package] ?? 1;
              return Card(
                child: ListTile(
                  contentPadding: UIStyles.tilePadding,
                  title: Text('${package.name} (${formatRand(package.price)})'),
                  trailing: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantity > 1) {
                                  _updateQuantity(package, quantity - 1);
                                } else {
                                  _toggleSelection(package);
                                }
                              },
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _updateQuantity(package, quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.check_box,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _toggleSelection(package),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.check_box_outline_blank),
                          onPressed: () => _toggleSelection(package),
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Selected: $totalItems items, Total: ${formatRand(totalPrice)}',
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Return selected packages to the caller so the caller can decide next step
            widget.onSelectionChanged(_selectedPackages);
              try {
                final names = _selectedPackages.keys.map((p) => p.name).join(', ');
                if (kDebugMode) debugPrint('PackagePicker confirm selected: $names');
              } catch (_) {}
            Navigator.of(context).pop(_selectedPackages);
          },
          child: const Text('Confirm Selection'),
        ),
      ],
    );
  }
}
