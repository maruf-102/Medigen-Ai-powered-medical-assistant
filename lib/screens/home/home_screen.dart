import 'package:flutter/material.dart';
import 'package:medigen/services/auth_service.dart';
import 'package:medigen/widgets/feature_card.dart';
import 'package:medigen/screens/find_doctor/find_doctor_screen.dart';
import 'package:medigen/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:medigen/screens/articles/articles_screen.dart';
import 'package:medigen/screens/forum/forum_screen.dart';
import 'package:medigen/screens/profile/patient_profile_screen.dart';
import 'package:medigen/screens/search/search_results_screen.dart';
import 'package:medigen/screens/blood_bank/blood_bank_screen.dart'; // Import Blood Bank

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(searchQuery: query.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'MediGen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await _authService.signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Your Health, Simplified',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find trusted doctors, get instant answers from our AI, and stay informed with expert health articles.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // --- Search Bar ---
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search doctors, articles, forums...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              const SizedBox(height: 30),

              // --- Feature Cards ---
              FeatureCard(
                icon: Icons.person_search,
                iconColor: Colors.teal,
                title: 'Find a Doctor',
                description:
                'Search our directory of verified specialists and book appointments online.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FindDoctorScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.blue,
                title: 'AI Health Assistant',
                description:
                'Get instant, helpful answers to your health questions 24/7 from our AI.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AiAssistantScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.article_outlined,
                iconColor: Colors.orange,
                title: 'Health Articles',
                description:
                'Read curated, easy-to-understand articles written by medical experts.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ArticlesScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.groups_outlined,
                iconColor: Colors.purple,
                title: 'Community Forum',
                description:
                'Connect with others, share experiences, and find support in our moderated forums.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForumScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- Updated Blood Bank Card ---
              // This now uses the same style as the others
              FeatureCard(
                icon: Icons.bloodtype,
                iconColor: Colors.red,
                title: 'Blood Bank',
                description: 'Find nearest blood donors and banks.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BloodBankScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}