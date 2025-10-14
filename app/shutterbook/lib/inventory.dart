import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final List<Map<String, dynamic>> _inventory = [
    {
      'name': 'Canon EOS R6',
      'category': 'Camera',
      'quantity': 2,
      'condition': 'Good',
    },
    {
      'name': 'Sigma 35mm Lens',
      'category': 'Lens',
      'quantity': 1,
      'condition': 'Excellent',
    },
    {
      'name': 'Softbox Light',
      'category': 'Lighting',
      'quantity': 3,
      'condition': 'Good',
    },
  ];

  void _addItem() => _showItemDialog();

  void _editItem(int index) {
    final item = _inventory[index];
    _showItemDialog(editIndex: index, existingItem: item);
  }

  void _showItemDialog({int? editIndex, Map<String, dynamic>? existingItem}) {
    String name = existingItem?['name'] ?? '';
    String category = existingItem?['category'] ?? '';
    int quantity = existingItem?['quantity'] ?? 1;
    String condition = existingItem?['condition'] ?? 'Good';

    final nameController = TextEditingController(text: name);
    final categoryController = TextEditingController(text: category);
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editIndex == null ? 'Add Inventory Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  controller: nameController,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  controller: categoryController,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  controller: quantityController,
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
              onPressed: () {
                final newName = nameController.text.trim();
                final newCategory = categoryController.text.trim();
                final newQuantity = int.tryParse(quantityController.text) ?? 1;

                if (newName.isEmpty || newCategory.isEmpty) return;

                setState(() {
                  if (editIndex == null) {
                    _inventory.add({
                      'name': newName,
                      'category': newCategory,
                      'quantity': newQuantity,
                      'condition': condition,
                    });
                  } else {
                    _inventory[editIndex] = {
                      'name': newName,
                      'category': newCategory,
                      'quantity': newQuantity,
                      'condition': condition,
                    };
                  }
                });
                Navigator.pop(context);
              },
              child: Text(editIndex == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) {
    setState(() {
      _inventory.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _inventory.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,          // two tiles per row
              childAspectRatio: 3 / 4,    // makes tiles taller
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = _inventory[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Category: ${item['category']}'),
                      Text('Quantity: ${item['quantity']}'),
                      const Spacer(), // pushes buttons to the bottom
                      Text(
                        'Condition: ${item['condition']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item['condition'] == 'Needs Repair'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () => _editItem(index),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () => _deleteItem(index),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}