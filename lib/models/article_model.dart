import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String summary;
  final String content; // <-- NEW FIELD

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.summary,
    required this.content, // <-- NEW
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      category: data['category'] ?? 'Uncategorized',
      imageUrl: data['imageUrl'] ?? '',
      summary: data['summary'] ?? 'No summary available.',
      content: data['content'] ?? 'No content available.', // <-- NEW
    );
  }
}