import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medigen/models/article_model.dart';
import 'article_detail_screen.dart'; // <-- NEW: Import the detail screen

// --- NEW: Converted to StatefulWidget ---
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  // --- NEW: Controller and search query ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Stream<QuerySnapshot> _articlesStream =
  FirebaseFirestore.instance.collection('articles').snapshots();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Health & Wellness Articles'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- NEW: Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search articles by title or category...',
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

          // --- Article List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _articlesStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No articles found.'));
                }

                // --- NEW: Filtering logic ---
                final List<Article> allArticles = snapshot.data!.docs
                    .map((doc) => Article.fromFirestore(doc))
                    .toList();

                final List<Article> filteredArticles = _searchQuery.isEmpty
                    ? allArticles
                    : allArticles.where((article) {
                  final title = article.title.toLowerCase();
                  final category = article.category.toLowerCase();
                  final summary = article.summary.toLowerCase();

                  return title.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      summary.contains(_searchQuery);
                }).toList();

                if (filteredArticles.isEmpty) {
                  return const Center(
                    child: Text(
                      'No articles match your search.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final Article article = filteredArticles[index];
                    return _ArticleListCard(article: article);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- UPDATED: _ArticleListCard ---
class _ArticleListCard extends StatelessWidget {
  final Article article;

  const _ArticleListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 3.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (article.imageUrl.isNotEmpty)
              ? Image.network(
            article.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          )
              : Container(
            height: 200,
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  article.summary,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16.0),

                // --- NEW: Made this section clickable ---
                InkWell(
                  onTap: () {
                    // This now works!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(article: article),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Don't take up full width
                      children: [
                        Text(
                          'Read More',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            color: Colors.teal[700], size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}