import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/models/booking.dart';
import 'package:shutterbook/data/tables/booking_table.dart';

class CreateBookingPage extends StatefulWidget {
  final Quote quote;

  const CreateBookingPage({super.key, required this.quote});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _statusController = TextEditingController(text: 'Scheduled');
  DateTime? _selectedDateTime;
  bool _saving = false;

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _selectedDateTime = combined);
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() => _saving = true);

    final booking = Booking(
      clientId: widget.quote.clientId,
      quoteId: widget.quote.id!,
      bookingDate: _selectedDateTime!,
      status: _statusController.text.trim().isEmpty
          ? 'Scheduled'
          : _statusController.text.trim(),
    );

    await BookingTable().insertBooking(booking);

    if (!mounted) return;
    setState(() => _saving = false);

    // Return to dashboard and indicate a booking was created
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text('Quote #${widget.quote.id}'),
              subtitle: Text(widget.quote.description),
            ),
            const SizedBox(height: 12),
            TextFormField(
              enabled: false,
              initialValue: widget.quote.clientId.toString(),
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              enabled: false,
              initialValue: widget.quote.id?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Quote ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.event),
              label: Text(
                _selectedDateTime == null
                    ? 'Select Date & Time'
                    : _selectedDateTime.toString(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              validator: (v) => null,
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _saveBooking,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Booking'),
                  ),
          ],
        ),
      ),
    );
  }
}
