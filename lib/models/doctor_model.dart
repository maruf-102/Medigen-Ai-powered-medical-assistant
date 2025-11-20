import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospitalName;
  final double rating;
  final String availability;
  final String initials;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospitalName,
    required this.rating,
    required this.availability,
    required this.initials,
  });

  // Factory constructor to create a Doctor from a Firestore document
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      specialty: data['specialty'] ?? 'No Specialty',
      hospitalName: data['hospitalName'] ?? 'No Hospital',
      rating: (data['rating'] ?? 0.0).toDouble(),
      availability: data['availability'] ?? 'Not Available',
      initials: data['initials'] ?? 'N/A',
    );
  }
}