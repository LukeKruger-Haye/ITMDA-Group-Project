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

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String category = '';
        int quantity = 1;
        String condition = 'Good';

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
              onPressed: () {
                setState(() {
                  _inventory.add({
                    'name': name,
                    'category': category,
                    'quantity': quantity,
                    'condition': condition,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
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
    resizeToAvoidBottomInset: true, // prevents overflow on keyboard
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
            crossAxisCount: 2,
            childAspectRatio: 4 / 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = _inventory[index];
            return SingleChildScrollView(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Category: ${item['category']}'),
                      Text('Quantity: ${item['quantity']}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Condition: ${item['condition']}',
                            style: TextStyle(
                              color: item['condition'] == 'Needs Repair'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _deleteItem(index),
                          ),
                        ],
                      ),
                    ],
                  ),
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