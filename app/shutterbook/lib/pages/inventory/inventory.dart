// Shutterbook — Inventory screen
// Manage inventory items (add/edit/remove) used in quotes and bookings.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';
import 'dart:io';
import '../../pages/inventory/items_details_page.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import '../../data/models/item.dart';
import '../../data/services/data_cache.dart';
import '../../widgets/section_card.dart';

class InventoryPage extends StatefulWidget {
  final bool embedded;
  // if true, open the add dialog automatically after the page loads
  final bool openAddOnLoad;
  const InventoryPage({super.key, this.embedded = false, this.openAddOnLoad = false});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryTable _inventoryTable = InventoryTable();
  List<Item> _inventory = [];
  List<Item> _filteredInventory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.openAddOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addItem();
      });
    }
  }

  Future<void> _loadItems() async  {
    final items = await _inventoryTable.getAllItems();
    setState(() {
      _inventory = items;
      _filteredInventory = items;
    });
  }

String _selectedCondition = 'All';

Future<void> refresh() async {
  await _loadItems(); // or whatever method reloads data
  setState(() {});
}

void _filterInventory(String query) {
  setState(() {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  });
}

void _applyFilters() {
  setState(() {
    _filteredInventory = _inventory.where((item) {
      final nameMatch = item.name.toLowerCase().contains(_searchQuery);
      final categoryMatch = item.category.toLowerCase().contains(_searchQuery);
      final conditionMatch = _selectedCondition == 'All' || item.condition == _selectedCondition;
      return (nameMatch || categoryMatch) && conditionMatch;
    }).toList();

    // Sort alphabetically
    _filteredInventory.sort((a, b) => a.name.compareTo(b.name));
  });
}

Future<void> _addItem() async {
  String name = '';
  String category = '';
  String condition = 'Good';
  String serialNumber = '';
  String? imagePath;

  // Validation error messages
  String? nameError;
  String? categoryError;
  String? conditionError;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Inventory Item'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      errorText: nameError,
                    ),
                    onChanged: (val) {
                      setState(() {
                        name = val;
                        nameError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      errorText: categoryError,
                    ),
                    onChanged: (val) {
                      setState(() {
                        category = val;
                        categoryError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Serial Number (optional)',
                    ),
                    onChanged: (val) {
                      setState(() {
                        serialNumber = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Condition',
                      errorText: conditionError,
                    ),
                    value: condition,
                    items: ['New', 'Excellent', 'Good', 'Needs Repair']
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        condition = val ?? 'Good';
                        conditionError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Show image preview if selected
                  if (imagePath != null)
                    Column(
                      children: [
                        Image.file(
                          File(imagePath!),
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => imagePath = null);
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: const Text(
                            'Remove Image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                  // Upload / Change image button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => imagePath = picked.path);
                      }
                    },
                    //styling the button
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32), // button background color
                          foregroundColor: Colors.white, // text/icon color
                        ),
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Inline validation per field
                  setState(() {
                    nameError = name.trim().isEmpty
                        ? 'Please enter an item name.'
                        : null;
                    categoryError = category.trim().isEmpty
                        ? 'Please enter a category.'
                        : null;
                    conditionError = condition.trim().isEmpty
                        ? 'Please select a condition.'
                        : null;
                  });

                  if (nameError != null ||
                      categoryError != null ||
                      conditionError != null) return;

                  final newItem = Item(
                    name: name.trim(),
                    category: category.trim(),
                    condition: condition.trim(),
                    serialNumber: serialNumber.trim().isEmpty
                        ? null
                        : serialNumber.trim(),
                    imagePath: imagePath,
                  );

                  await _inventoryTable.insertItem(newItem);
                  Navigator.pop(context);
                  await _loadItems();

                  // Success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Item "${newItem.name}" added successfully!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                },
                //styling the button
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32), // button background color
                          foregroundColor: Colors.white, // text/icon color
                        ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Inventory'),
      backgroundColor: Color(0xFF2E7D32),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by name or category',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterInventory,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Color(0xFF2E7D32), size: 28),
                tooltip: 'Filter by condition',
                onSelected: (value) {
                  setState(() {
                    _selectedCondition = value;
                    _applyFilters();
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'All', child: Text('All Conditions')),
                  const PopupMenuItem(value: 'New', child: Text('New')),
                  const PopupMenuItem(value: 'Excellent', child: Text('Excellent')),
                  const PopupMenuItem(value: 'Good', child: Text('Good')),
                  const PopupMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: _filteredInventory.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = _filteredInventory[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryDetailsPage(item: item),
                      ),
                    );

                    //Refresh inventory list when returning
                    await _loadItems();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        Expanded(
                          child: item.imagePath != null && item.imagePath!.isNotEmpty
                              ? Image.file(
                                  File(item.imagePath!),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),

                        // Text info section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${item.category}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Condition: ${item.condition}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.condition == 'Needs Repair'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addItem,
      backgroundColor: Color(0xFF2E7D32),
      child: const Icon(Icons.add),
    ),
  );
}
}