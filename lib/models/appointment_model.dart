import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String patientName;
  final Timestamp appointmentDateTime;
  final String status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.patientName,
    required this.appointmentDateTime,
    required this.status,
  });

  // Method to convert this object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientName': patientName,
      'appointmentDateTime': appointmentDateTime,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // Add a creation timestamp
    };
  }
}