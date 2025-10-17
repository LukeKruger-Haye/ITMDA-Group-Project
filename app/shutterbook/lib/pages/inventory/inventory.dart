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

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

Future<void> _loadItems() async {
  // Temporarily add a test item if database is empty
  final dbItems = await _inventoryTable.getAllItems();
  if (dbItems.isEmpty) {
    final testItem = Item(
      name: 'Camera Lens',
      category: 'Equipment',
      quantity: 5,
      condition: 'Excellent',
    );
    await _inventoryTable.insertItem(testItem);
    debugPrint('Inserted test item into Inventory!');
  }

  // Reload all items
  final items = await _inventoryTable.getAllItems();
  setState(() {
    _inventory = items;
  });

  debugPrint('Loaded ${_inventory.length} items from database.');
}

  Future<void> _addItem() async {
    String name = '';
    String category = '';
    int quantity = 1;
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
                TextField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) =>
                      quantity = int.tryParse(val) ?? 1,
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
                final newItem = Item(
                  name: name,
                  category: category,
                  quantity: quantity,
                  condition: condition,
                );
                await _inventoryTable.insertItem(newItem);
                Navigator.pop(context);
                _loadItems(); // refresh list
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
    int quantity = item.quantity;
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
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  controller: TextEditingController(text: name),
                  onChanged: (val) => name = val,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  controller: TextEditingController(text: category),
                  onChanged: (val) => category = val,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: quantity.toString()),
                  onChanged: (val) =>
                      quantity = int.tryParse(val) ?? item.quantity,
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
                final updatedItem = Item(
                  id: item.id,
                  name: name,
                  category: category,
                  quantity: quantity,
                  condition: condition,
                );
                await _inventoryTable.updateItem(updatedItem);
                Navigator.pop(context);
                _loadItems(); // refresh list
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
            tooltip: 'Add Item',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _inventory.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = _inventory[index];
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
                    Text('Quantity: ${item.quantity}'),
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
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _editItem(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}