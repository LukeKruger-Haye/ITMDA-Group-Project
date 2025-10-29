import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

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

  void _filterInventory(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredInventory = _inventory.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
               item.condition.toLowerCase().contains(_searchQuery);
      }).toList();
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
                  initialValue: 'Good',
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
                final newItem = Item(
                  name: name,
                  category: category,
                  condition: condition,
                );
                await _inventoryTable.insertItem(newItem);
                Navigator.pop(context);
                _loadItems();
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedItem = Item(
                  id: item.id,
                  name: name,
                  category: category,
                  condition: condition,
                );
                await _inventoryTable.updateItem(updatedItem);
                Navigator.pop(context);
                _loadItems();
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
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or condition',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterInventory,
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
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteItem(item.id!),
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