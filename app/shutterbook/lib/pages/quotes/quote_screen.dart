/*
import 'package:flutter/material.dart';
import 'package:shutterbook/main.dart';





class QuoteScreenState extends State<> {
  String? _dropdownValue; // holds the selected client value
  String? _dropdownValue2; // holds the selected package value

  void dropdownCallback(String? selectedValue) {
    if (selectedValue != null) {
      setState(() {
        _dropdownValue = selectedValue;
      });
    }
  }

  void dropdownCallback2(String? selectedValue) {
    if (selectedValue != null) {
      setState(() {
        _dropdownValue2 = selectedValue;
      });
    }
  }

  void onPressed() {
    if (_dropdownValue == null && _dropdownValue2 == null) {
      _showPopup("Error", "Client name and package were not selected.");
    } else if (_dropdownValue == null) {
      _showPopup("Missing Info", "Client name was not selected.");
    } else if (_dropdownValue2 == null) {
      _showPopup("Missing Info", "Package was not chosen.");
    } else {
      _showPopup("Success", "Quote created successfully!");
    }
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context, // now this context is below MaterialApp
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                title == "Success" ? Icons.check_circle : Icons.warning_amber_rounded,
                color: title == "Success" ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: QuoteScreen returns a Scaffold (not a MaterialApp) because MaterialApp
    // is already the root in main().
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Quote Generator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Client Name"),
              DropdownButton<String>(
                value: _dropdownValue,
                hint: const Text("Select Client"),
                items: const [
                  DropdownMenuItem(value: "Client A", child: Text("Client A")),
                  DropdownMenuItem(value: "Client B", child: Text("Client B")),
                  DropdownMenuItem(value: "Client C", child: Text("Client C")),
                ],
                onChanged: dropdownCallback,
              ),
              const SizedBox(height: 12),
              const Text("Client Email"),
              const SizedBox(height: 12),
              const Text("Item"),
              DropdownButton<String>(
                value: _dropdownValue2,
                hint: const Text("Select Item"),
                items: const [
                  DropdownMenuItem(value: "Birthday Package", child: Text("Birthday Package")),
                  DropdownMenuItem(value: "Wedding Package", child: Text("Wedding Package")),
                  DropdownMenuItem(value: "Anniversary Package", child: Text("Anniversary Package")),
                ],
                onChanged: dropdownCallback2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onPressed, child: const Text("Create")),
            ],
          ),
        ),
      ),
    );
  }
}
*/