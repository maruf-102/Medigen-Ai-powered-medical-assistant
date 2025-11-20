import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medigen/models/doctor_model.dart';
import 'booking_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final Future<DocumentSnapshot> _doctorFuture = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Doctor not found.'));
          }

          Doctor doctor = Doctor.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Section ---
                      Row(
                        children: [
                          // --- NEW: Added Hero Widget ---
                          Hero(
                            tag: 'doctor-avatar-${doctor.id}', // Must match!
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              child: Text(
                                doctor.initials,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ),
                          // --- END Hero Widget ---
                          const SizedBox(width: 20.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialty,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber[600], size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor.rating} (${doctor.availability})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 40, thickness: 1),

                      // --- Bio Section ---
                      const Text(
                        'About Doctor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dr. ${doctor.name} is a highly respected ${doctor.specialty} at ${doctor.hospitalName} with over 10 years of experience. (This is a placeholder bio. You can add a "bio" field to your Firestore document.)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                      const Divider(height: 40, thickness: 1),

                      // --- Hospital Info ---
                      const Text(
                        'Hospital',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.local_hospital,
                            color: Colors.teal, size: 30),
                        title: Text(doctor.hospitalName,
                            style: const TextStyle(fontSize: 16)),
                        subtitle: const Text('123 Main St, Cityville'),
                      ),
                    ],
                  ),
                ),
              ),

              // --- "Book Appointment" Button ---
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(doctor: doctor),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Book an Appointment'),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}