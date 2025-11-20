import 'package:mongo_dart/mongo_dart.dart';

class BloodDonor {
  final ObjectId id; // MongoDB uses ObjectId, not String for IDs
  final String name;
  final String bloodGroup;
  final String contactNumber;
  final String location; // Just a text address (e.g., "Mirpur, Dhaka")

  BloodDonor({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.contactNumber,
    required this.location,
  });

  // Convert from MongoDB Document to Dart Object
  factory BloodDonor.fromJson(Map<String, dynamic> json) {
    return BloodDonor(
      id: json['_id'],
      name: json['name'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      location: json['location'] ?? '',
    );
  }

  // Convert from Dart Object to MongoDB Document
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bloodGroup': bloodGroup,
      'contactNumber': contactNumber,
      'location': location,
    };
  }
}