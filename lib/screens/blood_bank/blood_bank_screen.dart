import 'package:flutter/material.dart';
import 'package:medigen/models/blood_donor_model.dart';
import 'package:medigen/services/mongo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodBankScreen extends StatefulWidget {
  const BloodBankScreen({super.key});

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  String _selectedFilter = 'All'; // Default filter
  List<BloodDonor> _donors = [];
  bool _isLoading = true;

  final List<String> _bloodGroups = ['All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  // Fetch donors from MongoDB
  Future<void> _fetchDonors() async {
    setState(() { _isLoading = true; });

    final data = await MongoService.getDonors(_selectedFilter);

    setState(() {
      _donors = data;
      _isLoading = false;
    });
  }

  // Show dialog to add a new donor
  void _showAddDonorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    String selectedGroup = 'A+';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Become a Donor"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGroup,
                items: _bloodGroups
                    .where((g) => g != 'All') // Don't show 'All' in registration
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => selectedGroup = val!,
                decoration: const InputDecoration(labelText: "Blood Group"),
              ),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location (e.g. Mirpur)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await MongoService.addDonor(
                  nameController.text.trim(),
                  selectedGroup,
                  phoneController.text.trim(),
                  locationController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered successfully!")));
                }
                _fetchDonors(); // Refresh list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Register"),
          )
        ],
      ),
    );
  }

  // Helper to make phone calls
  void _callDonor(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Blood Bank"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- Filter Bar ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text("Filter by: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedFilter = val!);
                          _fetchDonors(); // Fetch new data when filter changes
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Donor List ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _donors.isEmpty
                ? const Center(child: Text("No donors found for this group."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _donors.length,
              itemBuilder: (context, index) {
                final donor = _donors[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Text(
                        donor.bloodGroup,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(donor.location, style: const TextStyle(fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(donor.contactNumber, style: const TextStyle(fontSize: 13)),
                        ]),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 18,
                        child: Icon(Icons.call, color: Colors.white, size: 18),
                      ),
                      onPressed: () => _callDonor(donor.contactNumber),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDonorDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Be a Donor", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}