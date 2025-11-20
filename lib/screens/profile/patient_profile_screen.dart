import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // -- Text Controllers --
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  // --- NEW: Emergency Medical ID Controllers ---
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _profilePicUrl;

  bool _isLoading = false;
  String _bmi = '0.0';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    // --- NEW: Dispose new controllers ---
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  // --- UPDATED: Load User Data ---
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    setState(() { _isLoading = true; });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['fullName'] ?? '';
        _bloodGroupController.text = data['bloodGroup'] ?? '';
        _heightController.text = data['height'] ?? '';
        _weightController.text = data['weight'] ?? '';
        _profilePicUrl = data['profilePicUrl'];

        // --- NEW: Load Medical ID data ---
        _allergiesController.text = data['allergies'] ?? '';
        _medicationsController.text = data['medications'] ?? '';
        _emergencyContactController.text = data['emergencyContact'] ?? '';

        _calculateBmi();
      }
    } catch (e) {
      _showError('Error loading user data: $e');
    }

    setState(() { _isLoading = false; });
  }

  // --- Pick a New Image ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- UPDATED: Save Profile ---
  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() { _isLoading = true; });

    try {
      String? newImageUrl = _profilePicUrl;

      // Step 1: If a new image was picked, upload it
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(currentUser!.uid + '.jpg');

        await ref.putFile(_imageFile!);
        newImageUrl = await ref.getDownloadURL();
      }

      // Step 2: Update (or create) the user's document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({
        'fullName': _nameController.text.trim(),
        'profilePicUrl': newImageUrl,
        'bloodGroup': _bloodGroupController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'email': currentUser!.email,

        // --- NEW: Save Medical ID data ---
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),

      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      setState(() {
        _profilePicUrl = newImageUrl;
        _imageFile = null;
      });

    } catch (e) {
      _showError('Error updating profile: $e');
    }

    setState(() { _isLoading = false; });
  }

  // ... (Cancel Appointment, Calculate BMI, and Error helpers are the same) ...
  Future<void> _cancelAppointment(String appointmentId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == null || confirm == false) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Error cancelling appointment: $e');
    }
  }

  void _calculateBmi() {
    final double height = double.tryParse(_heightController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      final double heightInMeters = height / 100;
      final double bmiValue = weight / (heightInMeters * heightInMeters);
      setState(() {
        _bmi = bmiValue.toStringAsFixed(1);
      });
    } else {
      setState(() {
        _bmi = '0.0';
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Profile Picture Section ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                        ? NetworkImage(_profilePicUrl!)
                        : null,
                    child: (_imageFile == null &&
                        (_profilePicUrl == null ||
                            _profilePicUrl!.isEmpty))
                        ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Basic Info ---
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController(),
              label: 'Email',
              readOnly: true,
            ),
            const SizedBox(height: 20),

            // --- Medical Vitals ---
            _buildTextField(
              controller: _bloodGroupController,
              label: 'Blood Group (e.g., O+, A-)',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your BMI:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _bmi,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- NEW: Emergency Medical ID Section ---
            const Divider(height: 40, thickness: 1),
            const Text(
              'Emergency Medical ID',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _allergiesController,
              label: 'Allergies (e.g., Peanuts, Penicillin)',
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _medicationsController,
              label: 'Current Medications (e.g., Atorvastatin)',
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emergencyContactController,
              label: 'Emergency Contact (Name & Phone)',
              keyboardType: TextInputType.phone,
            ),
            // --- End of New Section ---

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
            const Divider(height: 50, thickness: 1),

            // --- My Appointments Section ---
            Text(
              'My Appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildMyAppointmentsList(),
          ],
        ),
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences, // Capitalize sentences
      minLines: 1,
      maxLines: (keyboardType == TextInputType.multiline) ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true, // Good for multiline
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
      ),
    );
  }

  TextEditingController _emailController() {
    return TextEditingController(text: currentUser?.email ?? 'No Email');
  }

  // --- Appointments list widget ---
  Widget _buildMyAppointmentsList() {
    if (currentUser == null) {
      return const Center(child: Text("Please log in to see appointments."));
    }

    final Stream<QuerySnapshot> appointmentsStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser!.uid)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime', descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: appointmentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have no upcoming appointments.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp timestamp = data['dateTime'];
            final DateTime dateTime = timestamp.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  'Dr. ${data['doctorName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(dateTime)} - ${DateFormat.jm().format(dateTime)}',
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () => _cancelAppointment(doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}