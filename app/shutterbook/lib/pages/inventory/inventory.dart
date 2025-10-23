import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

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
  }

  Future<void> _loadItems() async {
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

  await showDialog(
    context: context,
    builder: (context) {
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Condition'),
                value: 'Good',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              //Validation: check if all fields are filled
              if (name.trim().isEmpty || category.trim().isEmpty || condition.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields before adding the item.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              //Proceed if all fields are valid
              final newItem = Item(
                name: name.trim(),
                category: category.trim(),
                condition: condition.trim(),
              );

              await _inventoryTable.insertItem(newItem);
              Navigator.pop(context);
              await _loadItems();

              ScaffoldMessenger.of(context).showSnackBar(
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
}

  Future<void> _editItem(Item item) async {
  String name = item.name;
  String category = item.category;
  String condition = item.condition;

  await showDialog(
    context: context,
    builder: (context) {
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
                value: condition,
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
            onPressed: () => Navigator.pop(context),
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

              await _inventoryTable.updateItem(updatedItem);
              Navigator.pop(context);
              await _loadItems();

              ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _deleteItem(int id) async {
    await _inventoryTable.deleteItem(id);
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
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Category: ${item.category}'),
                          Text(
                            'Condition: ${item.condition}',
                            style: TextStyle(
                              color: item.condition == 'Needs Repair'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () => _editItem(item),
                              ),
                              IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text('Are you sure you want to delete "${item.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _deleteItem(item.id!); // Your existing delete method
                                }
                              },
                            ),
                            ],
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