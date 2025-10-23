import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/data/tables/package_table.dart';

class PackageAdd  extends StatefulWidget{
    const PackageAdd({super.key});

  @override
  PackageAddState createState() => PackageAddState();
}

class PackageAddState extends State<PackageAdd>{
List<Package> allPackages=[];



@override
  void initState() {
    super.initState();
    _loadPackages();
  }


Future<void> _loadPackages() async{
final packages= await PackageTable().getAllPackages();

setState(() {
  allPackages=packages;
});
  

}

String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();


  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

Future<void> _addOrEditPackages({Package? package}) async{
final packageNameController= TextEditingController(text: package?.name??'');
final packagePriceController=TextEditingController();
final packageDescriptionController=TextEditingController(text: package?.details??'');
final formKey = GlobalKey<FormState>();

final result = await showDialog(
  context: context,
  builder:(context)=>AlertDialog(
    title: Text(package==null ? 'Add Package' : 'Edit Package'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
      child:Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            TextFormField(
              controller: packageNameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value==null || value.trim().isEmpty? 'Package Name required': null,
              textCapitalization: TextCapitalization.words,
            ),
             TextFormField(
              controller: packagePriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // Allows digits and at most one decimal point
                     ],
              decoration: const InputDecoration(labelText: 'Price'),
              validator: (value) => value==null || value.trim().isEmpty? 'Package Price required': null,
              textCapitalization: TextCapitalization.words,
            ),
             TextFormField(
              controller: packageDescriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) => value==null || value.trim().isEmpty? 'Package Name required': null,
              textCapitalization: TextCapitalization.words,
            ),

        ],
        
      )
    )
  ),
  actions: [
       TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final confirmed = await _showConfirmationDialog(
                  package == null ? 'Add Package' : 'Save Changes',
                  package == null
                      ? 'Are you sure you want to add this package?'
                      : 'Are you sure you want to save changes to this package?',
                );
                if (!confirmed) return;
                final newPackage = Package(
                  id: package?.id,
                  name:_capitalize(packageNameController.text.trim()),
                  price: double.parse(packagePriceController.text),
                  details: _capitalize(packageDescriptionController.text.trim()),
                
                );
                Navigator.pop(context, newPackage);
              }
            },
            child: const Text('Save'),
          ),
        ],
  
) 
);
 if (result != null) {
      if (package == null) {
        await PackageTable().insertPackage(result);
      } else {
        await PackageTable().updatePackage(result);
      }
      _loadPackages();
    }



}
Future<void> _deletePackage(Package package) async{


 final confirmed = await _showConfirmationDialog(
      'Delete Package', 
      'Are you sure you want to delete ${package.name}?',
    );
    if (confirmed && package.id != null) {
      await PackageTable().deletePackages(package.id!);
      _loadPackages();
    }


}

  



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packages')),
      body: allPackages.isEmpty
        ? const Center(child:Text('No Packages found')):
        ListView.builder(
        itemCount: allPackages.length,
        itemBuilder: (context, index) {
          final package = allPackages[index];
          return ListTile(
            title: Text('${package.name} R${package.price}'),
            subtitle: Text(package.details),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditPackages(package: package),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deletePackage(package),
                  tooltip: 'Delete',
                ),
              ],
            ),
          );
        },
      ),
      
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPackages(),
        tooltip: 'Add Package',
        child: const Icon(Icons.add),
      ),
      
      
    );
  }



  
  


  }