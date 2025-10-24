import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import '../../data/tables/inventory_table.dart';

class ItemDetailsPage extends StatefulWidget {
  final Item item;

  const ItemDetailsPage({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final InventoryTable _inventoryTable = InventoryTable();
  int _selectedTabIndex = 0;

  Future<void> _editItem() async {
    String name = widget.item.name;
    String category = widget.item.category;
    String condition = widget.item.condition;

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
                if (name.trim().isEmpty || category.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final updatedItem = Item(
                  id: widget.item.id,
                  name: name.trim(),
                  category: category.trim(),
                  condition: condition.trim(),
                  imagePath: widget.item.imagePath,
                  serialNumber: widget.item.serialNumber,
                );

                await _inventoryTable.updateItem(updatedItem);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item "${updatedItem.name}" updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );

                setState(() {
                  widget.item.name = updatedItem.name;
                  widget.item.category = updatedItem.category;
                  widget.item.condition = updatedItem.condition;
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${widget.item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _inventoryTable.deleteItem(widget.item.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to inventory page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.teal[100],
            child: Row(
              children: [
                _buildTabButton('Info', 0),
                _buildTabButton('Bookings', 1),
              ],
            ),
          ),
          Expanded(
            child: _selectedTabIndex == 0 ? _buildInfoTab() : _buildBookingsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() => _selectedTabIndex = index),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          widget.item.imagePath != null && widget.item.imagePath!.isNotEmpty
              ? Image.file(File(widget.item.imagePath!), height: 180, fit: BoxFit.cover)
              : Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
                ),
          const SizedBox(height: 16),
          Text(widget.item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Category: ${widget.item.category}', style: const TextStyle(fontSize: 16)),
          Text('Condition: ${widget.item.condition}', style: const TextStyle(fontSize: 16)),
          if (widget.item.serialNumber != null && widget.item.serialNumber!.isNotEmpty)
            Text('Serial Number: ${widget.item.serialNumber}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _editItem,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              ElevatedButton.icon(
                onPressed: _deleteItem,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return const Center(
      child: Text('No bookings yet.'),
    );
  }
}