import 'package:flutter/material.dart';
import 'package:medigen/models/article_model.dart';
import 'package:medigen/models/doctor_model.dart';
import 'package:medigen/models/forum_thread_model.dart';
import 'package:medigen/models/search_result_model.dart';
import 'package:medigen/services/search_service.dart';
import 'package:medigen/screens/articles/article_detail_screen.dart';
import 'package:medigen/screens/find_doctor/doctor_profile_screen.dart';
import 'package:medigen/screens/forum/thread_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;
  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final SearchService _searchService = SearchService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Results for "$searchQuery"'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<SearchResult>>(
        future: _searchService.searchAll(searchQuery), // Call the search
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No results found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final results = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              // Build a different card based on the result type
              return _buildResultCard(context, result);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResult result) {
    IconData icon;
    Color color;

    // Assign icon and color based on type
    switch (result.type) {
      case SearchResultType.doctor:
        icon = Icons.person_search;
        color = Colors.teal;
        break;
      case SearchResultType.article:
        icon = Icons.article_outlined;
        color = Colors.orange;
        break;
      case SearchResultType.forum:
        icon = Icons.groups_outlined;
        color = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(result.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to the correct detail page
          _navigateToResult(context, result);
        },
      ),
    );
  }

  // --- Navigation logic ---
  void _navigateToResult(BuildContext context, SearchResult result) {
    switch (result.type) {
      case SearchResultType.doctor:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfileScreen(doctorId: result.documentId),
          ),
        );
        break;
      case SearchResultType.article:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: result.originalObject as Article),
          ),
        );
        break;
      case SearchResultType.forum:
        final thread = result.originalObject as ForumThread;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ThreadDetailScreen(
              threadId: thread.id,
              threadTitle: thread.title, authorId: '',
            ),
          ),
        );
        break;
    }
  }
}