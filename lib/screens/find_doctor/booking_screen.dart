import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medigen/models/doctor_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Hardcoded time slots for simplicity
  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- Main Booking Function ---
  Future<void> _bookAppointment() async {
    if (currentUser == null) {
      _showError("You must be logged in to book an appointment.");
      return;
    }
    if (_selectedDay == null || _selectedTimeSlot == null) {
      _showError("Please select a date and time slot.");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Get the patient's name from the 'users' collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final String patientName = userDoc.data()?['fullName'] ?? currentUser!.email ?? 'Unknown Patient';

      // 2. Combine the selected date and time
      final DateFormat parser = DateFormat('h:mm a'); // "09:00 AM"
      final DateTime time = parser.parse(_selectedTimeSlot!);

      final DateTime appointmentDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        time.hour,
        time.minute,
      );

      // 3. Create the new appointment document in Firestore
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': currentUser!.uid,
        'patientName': patientName,
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'doctorSpecialty': widget.doctor.specialty,
        'dateTime': Timestamp.fromDate(appointmentDateTime),
        'status': 'Confirmed',
        'createdAt': Timestamp.now(),
      });

      // 4. Show success and navigate back
      Navigator.of(context).pop(); // Close booking screen
      Navigator.of(context).pop(); // Close doctor profile
      _showSuccess("Appointment booked successfully!");

    } catch (e) {
      _showError("Error booking appointment: $e");
    }

    setState(() { _isLoading = false; });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Book with ${widget.doctor.name}'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Calendar ---
                  _buildCalendar(),
                  const Divider(height: 30),

                  // --- Time Slots ---
                  Text(
                    'Choose a time slot for ${DateFormat.yMMMd().format(_selectedDay!)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeSlotGrid(),
                ],
              ),
            ),
          ),

          // --- "Confirm" Button ---
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
              ],
            ),
            child: ElevatedButton(
              onPressed: (_selectedTimeSlot == null || _isLoading)
                  ? null // Disable button if no time is selected or loading
                  : _bookAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Booking'),
            ),
          )
        ],
      ),
    );
  }

  // --- Calendar Widget ---
  Widget _buildCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedTimeSlot = null; // Reset time slot when day changes
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  // --- Time Slot Grid Widget ---
  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Disables scrolling in the grid
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final isSelected = _selectedTimeSlot == slot;

        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTimeSlot = selected ? slot : null;
            });
          },
          selectedColor: Colors.teal,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.teal : Colors.grey[300]!,
            ),
          ),
        );
      },
    );
  }
}