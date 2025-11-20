import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medigen/models/doctor_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  // Example time slots
  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM'
  ];

  // --- 1. Date Picker Function ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Users can't book in the past
      lastDate: DateTime.now().add(const Duration(days: 60)), // 2-month window
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  // --- 2. Booking Confirmation Function ---
  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot.')),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Fetch the user's name from their profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final patientName = (userDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Patient';

      // Combine date and time
      final int hour = int.parse(_selectedTimeSlot!.split(':')[0]);
      final int minute = int.parse(_selectedTimeSlot!.split(':')[1].split(' ')[0]);
      final bool isPM = _selectedTimeSlot!.endsWith('PM');

      final DateTime finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        isPM && hour != 12 ? hour + 12 : (isPM == false && hour == 12 ? 0 : hour),
        minute,
      );

      // Create a new document in the 'appointments' collection
// Create a new document in the 'appointments' collection
      final newAppointmentRef =
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': currentUser!.uid,
        'patientName': patientName,
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'appointmentDateTime': Timestamp.fromDate(finalDateTime),
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

// Get the new appointment ID
      final newAppointmentId = newAppointmentRef.id;

// WITH THIS:
      setState(() { _isLoading = false; }); // Stop loading first

// Show a success dialog
      showDialog(
        context: context,
        barrierDismissible: false, // User must tap a button
        builder: (ctx) => AlertDialog(
          title: const Text('Appointment Confirmed!'),
          content: Text(
              'Your appointment with ${widget.doctor.name} on ${DateFormat.yMMMd().format(_selectedDate!)} at $_selectedTimeSlot is booked.'
          ),
          actions: [
            // 'Cancel' button
            TextButton(
              onPressed: () async {
                // Delete the appointment
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(newAppointmentId)
                    .delete();

                // Close the dialog and the booking screen
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled.')),
                );
              },
              child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
            ),
            // 'OK' button
            TextButton(
              onPressed: () {
                // Close the dialog and the booking screen
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    } finally {
     
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Doctor Info ---
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: Text(
                    widget.doctor.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specialty,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),

            // --- Date Picker ---
            const Text(
              'Select a Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Choose a date'
                          : DateFormat.yMMMd().format(_selectedDate!), // 'Nov 12, 2025'
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_month, color: Colors.teal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Time Slot Picker ---
            const Text(
              'Select a Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: _timeSlots.map((time) {
                final bool isSelected = _selectedTimeSlot == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeSlot = selected ? time : null;
                    });
                  },
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 50),

            // --- Confirm Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                )
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}