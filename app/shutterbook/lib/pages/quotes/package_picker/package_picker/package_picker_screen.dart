import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_add/package_add.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_picker/package_picker.dart';

class PackagePickerScreen extends StatelessWidget {
  final Client client;

  const PackagePickerScreen({super.key, required this.client});

  void _onSelectionChanged(Map<Package, int> selectedPackages) {
    // You can handle the selected packages here (e.g., save, show dialog, etc.)
    debugPrint('Selected packages: ${selectedPackages.keys.map((p) => p.name).join(', ')}');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Packages'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            icon: const Icon(Icons.home),
          ),
              IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context)=> const PackageAdd())
                );
            },
            icon: const Icon(Icons.indeterminate_check_box_rounded),
            ),
        ],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PackagePicker(
          onSelectionChanged: _onSelectionChanged,
          client: client,),
      ),
    );
  }
}