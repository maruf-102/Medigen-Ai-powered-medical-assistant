import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:medigen/models/blood_donor_model.dart';

class MongoService {
  // --- ⚠️ REPLACE THIS WITH YOUR COPIED STRING ---
  // Replace <db_password> with your actual password for 'maruf1minhaz_db_user'
  static const String _connectionString =
      "mongodb+srv://maruf1minhaz_db_user:<password>@medigen.jgvmk1n.mongodb.net/?appName=medigen";

  static Db? _db;
  static DbCollection? _donorCollection;

  // 1. Connect to Database
  static Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      _donorCollection = _db!.collection('blood_donors');
      log("✅ Connected to MongoDB!");
    } catch (e) {
      log("❌ MongoDB Connection Error: $e");
    }
  }

  // --- BULK INSERT FUNCTION ---
  static Future<void> addBulkDonors() async {
    if (_donorCollection == null) return;

    // A list of 20 dummy donors
    var bulkData = [
      {'name': 'Rahim Uddin', 'bloodGroup': 'A+', 'contactNumber': '01711111111', 'location': 'Mirpur 10', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Karim Hasan', 'bloodGroup': 'B+', 'contactNumber': '01722222222', 'location': 'Dhanmondi 32', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Fatima Begum', 'bloodGroup': 'O+', 'contactNumber': '01733333333', 'location': 'Uttara Sector 7', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Sultana Razia', 'bloodGroup': 'AB+', 'contactNumber': '01744444444', 'location': 'Banani', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Abdul Malek', 'bloodGroup': 'A-', 'contactNumber': '01755555555', 'location': 'Mohammadpur', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Nusrat Jahan', 'bloodGroup': 'B-', 'contactNumber': '01766666666', 'location': 'Gulshan 1', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Kamal Hossain', 'bloodGroup': 'O-', 'contactNumber': '01777777777', 'location': 'Badda', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Jamal Uddin', 'bloodGroup': 'AB-', 'contactNumber': '01788888888', 'location': 'Rampura', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Rubina Akter', 'bloodGroup': 'A+', 'contactNumber': '01799999999', 'location': 'Malibagh', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Sohel Rana', 'bloodGroup': 'B+', 'contactNumber': '01611111111', 'location': 'Farmgate', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Nasrin Sultana', 'bloodGroup': 'O+', 'contactNumber': '01622222222', 'location': 'Tejgaon', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Arifur Rahman', 'bloodGroup': 'AB+', 'contactNumber': '01633333333', 'location': 'Shahbag', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Moushumi Kabir', 'bloodGroup': 'A-', 'contactNumber': '01644444444', 'location': 'Lalmatia', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Farid Ahmed', 'bloodGroup': 'B-', 'contactNumber': '01655555555', 'location': 'Khilgaon', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Salma Khatun', 'bloodGroup': 'O-', 'contactNumber': '01666666666', 'location': 'Bashundhara', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Rafiqul Islam', 'bloodGroup': 'AB-', 'contactNumber': '01677777777', 'location': 'Baridhara', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Tasnim Zara', 'bloodGroup': 'A+', 'contactNumber': '01688888888', 'location': 'Niketon', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Shakil Ahmed', 'bloodGroup': 'B+', 'contactNumber': '01699999999', 'location': 'Agargaon', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Jannatul Ferdous', 'bloodGroup': 'O+', 'contactNumber': '01511111111', 'location': 'Shyamoli', 'createdAt': DateTime.now().toIso8601String()},
      {'name': 'Mehedi Hasan', 'bloodGroup': 'AB+', 'contactNumber': '01522222222', 'location': 'Gabtoli', 'createdAt': DateTime.now().toIso8601String()},
    ];

    await _donorCollection!.insertAll(bulkData);
    print("✅ Bulk data added successfully!");
  }

  // 2. Get Donors (Optional: Filter by Blood Group)
  static Future<List<BloodDonor>> getDonors(String? bloodGroup) async {
    if (_donorCollection == null) return [];

    final selector = where;

    // If a specific group is chosen (e.g., "A+"), filter by it.
    // If "All" is chosen, we pass an empty selector to get everyone.
    if (bloodGroup != null && bloodGroup != "All") {
      selector.eq('bloodGroup', bloodGroup);
    }

    // Sort by name (optional)
    selector.sortBy('name');

    final list = await _donorCollection!.find(selector).toList();
    return list.map((json) => BloodDonor.fromJson(json)).toList();
  }

  // 3. Add a New Donor
  static Future<void> addDonor(String name, String group, String phone, String location) async {
    if (_donorCollection == null) return;

    await _donorCollection!.insert({
      'name': name,
      'bloodGroup': group,
      'contactNumber': phone,
      'location': location,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // 4. Close Connection (Good practice)
  static Future<void> close() async {
    await _db?.close();
  }
}
