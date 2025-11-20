import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medigen/models/doctor_model.dart';
import 'package:medigen/models/doctor_category_model.dart'; // NEW IMPORT
import 'doctor_profile_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // NEW: To hold the currently selected category

  final Stream<QuerySnapshot> _doctorsStream =
  FirebaseFirestore.instance.collection('doctors').snapshots();
  final Stream<QuerySnapshot> _topDoctorsStream = FirebaseFirestore.instance
      .collection('doctors')
      .orderBy('rating', descending: true)
      .limit(5)
      .snapshots();
  final Stream<QuerySnapshot> _hospitalsStream =
  FirebaseFirestore.instance.collection('hospitals').limit(5).snapshots();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        // If search query is active, clear category selection
        if (_searchQuery.isNotEmpty) {
          _selectedCategory = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // NEW: Function to handle category selection
  void _onCategorySelected(String categoryName) {
    setState(() {
      if (_selectedCategory == categoryName) {
        _selectedCategory = null; // Deselect if already selected
      } else {
        _selectedCategory = categoryName;
        _searchController.clear(); // Clear search if a category is selected
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Find Your Doctor'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, specialty...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                ),
              ),
            ),

            // --- NEW: Doctor Categories List ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Pick Your Specialist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 120, // Height for category icons
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: DoctorCategory.defaultCategories.length,
                itemBuilder: (context, index) {
                  final category = DoctorCategory.defaultCategories[index];
                  bool isSelected = _selectedCategory == category.name;

                  return GestureDetector(
                    onTap: () => _onCategorySelected(category.name),
                    child: Container(
                      width: 90, // Width of each category item
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            category.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.category, size: 40, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.teal : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20), // Space after categories
            // --- END NEW CATEGORY SECTION ---


            // --- Nearby Hospitals ---
            _buildHorizontalList(
              title: 'Nearby Hospitals',
              stream: _hospitalsStream,
              builder: (doc) =>
                  _HospitalCard(doc: doc),
            ),

            // --- Top Rated Doctors ---
            _buildHorizontalList(
              title: 'Top Rated Doctors',
              stream: _topDoctorsStream,
              builder: (doc) {
                final doctor = Doctor.fromFirestore(doc);
                return _TopDoctorCard(doctor: doctor);
              },
            ),

            // --- All Doctors (Searchable List) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'All Doctors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSearchableDoctorList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList({
    required String title,
    required Stream<QuerySnapshot> stream,
    required Widget Function(DocumentSnapshot) builder,
  }) {
    // ... (This widget is unchanged)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180.0, // Fixed height from overflow
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No data found.'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  return builder(snapshot.data!.docs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _HospitalCard({required DocumentSnapshot doc}) {
    // ... (This widget is unchanged)
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              data['imageUrl'] ?? '',
              height: 90,
              width: 150,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 90,
                width: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.local_hospital, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data['name'] ?? 'Hospital',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                data['distance'] ?? '... km',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TopDoctorCard({required Doctor doctor}) {
    // ... (This widget is unchanged)
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfileScreen(doctorId: doctor.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'doctor-avatar-${doctor.id}', // Unique tag
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    child: Text(
                      doctor.initials,
                      style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  doctor.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber[600], size: 16),
                    Text(
                      ' ${doctor.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED: This widget now filters by category as well ---
  Widget _buildSearchableDoctorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _doctorsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No doctors found.'));
        }

        final List<Doctor> allDoctors = snapshot.data!.docs
            .map((doc) => Doctor.fromFirestore(doc))
            .toList();

        // NEW: Filtering logic - combines search query AND selected category
        final List<Doctor> filteredDoctors = allDoctors.where((doctor) {
          final matchesSearch = _searchQuery.isEmpty ||
              doctor.name.toLowerCase().contains(_searchQuery) ||
              doctor.specialty.toLowerCase().contains(_searchQuery) ||
              doctor.hospitalName.toLowerCase().contains(_searchQuery);

          final matchesCategory = _selectedCategory == null ||
              doctor.specialty.toLowerCase() == _selectedCategory!.toLowerCase();

          return matchesSearch && matchesCategory;
        }).toList();


        if (filteredDoctors.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _selectedCategory != null
                    ? 'No ${_selectedCategory}s found.'
                    : 'No doctors match your search.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDoctors.length,
            itemBuilder: (context, index) {
              final Doctor doctor = filteredDoctors[index];

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _DoctorListCard(doctor: doctor),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorListCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    // ... (This widget is unchanged)
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Hero(
              tag: 'doctor-avatar-${doctor.id}',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: Text(
                  doctor.initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doctor.specialty} - ${doctor.hospitalName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.check_circle,
                          color: Colors.green[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        doctor.availability,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DoctorProfileScreen(doctorId: doctor.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }
}