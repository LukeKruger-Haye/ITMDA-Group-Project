// Shutterbook — Inventory screen
// Manage inventory items (add/edit/remove) used in quotes and bookings.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';
import 'dart:io';
import '../../pages/inventory/items_details_page.dart';
import '../../data/services/data_cache.dart';

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

  Future<void> _loadItems() async {
    try {
      final items = await DataCache.instance.getInventory();
      setState(() {
        _inventory = items;
        _filteredInventory = items;
      });
      return;
    } catch (_) {}
  final items = await _inventoryTable.getAllItems();
    setState(() {
      _inventory = items;
      _filteredInventory = items;
    });
  }

String _selectedCondition = 'All';

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

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Inventory Item'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    onChanged: (val) => name = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Category'),
                    onChanged: (val) => category = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Serial Number (optional)'),
                    onChanged: (val) => serialNumber = val,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Condition'),
                    initialValue: 'Good',
                    items: ['New', 'Excellent', 'Good', 'Needs Repair']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => condition = val ?? 'Good',
                  ),
                  const SizedBox(height: 10),
                  if (imagePath != null)
                    Column(
                      children: [
                        Image.file(
                          File(imagePath!),
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => imagePath = picked.path);
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validation for required fields
                  if (name.trim().isEmpty || category.trim().isEmpty || condition.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields before adding the item.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final newItem = Item(
                    name: name.trim(),
                    category: category.trim(),
                    condition: condition.trim(),
                    serialNumber: serialNumber.trim().isEmpty ? null : serialNumber.trim(),
                    imagePath: imagePath,
                  );

                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  await _inventoryTable.insertItem(newItem);
                  if (navigator.mounted) navigator.pop();
                  await _loadItems();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Item "${newItem.name}" added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  // ignore: unused_element
  Future<void> _editItem(Item item) async {
  String name = item.name;
  String category = item.category;
  String condition = item.condition;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: TextEditingController(text: name),
                decoration: const InputDecoration(labelText: 'Item Name'),
                onChanged: (val) => name = val,
              ),
              TextField(
                controller: TextEditingController(text: category),
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (val) => category = val,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Condition'),
                initialValue: condition,
                items: ['New', 'Excellent', 'Good', 'Needs Repair']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => condition = val ?? 'Good',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              //Validate before saving
              if (name.trim().isEmpty || category.trim().isEmpty || condition.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields before saving changes.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              final updatedItem = Item(
                id: item.id,
                name: name.trim(),
                category: category.trim(),
                condition: condition.trim(),
              );

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              await _inventoryTable.updateItem(updatedItem);
              if (navigator.mounted) navigator.pop();
              await _loadItems();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Item "${updatedItem.name}" updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  // ignore: unused_element
  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    await _inventoryTable.deleteItem(id);
    DataCache.instance.clearInventory();
    _loadItems();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Inventory'),
      backgroundColor: Colors.teal,
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
                icon: const Icon(Icons.filter_list, color: Colors.teal, size: 28),
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
      backgroundColor: Colors.teal,
      child: const Icon(Icons.add),
    ),
  );
}
}