import 'package:cloud_firestore/cloud_firestore.dart';

class ForumThread {
  final String id;
  final String title;
  final String category;
  final String authorName;
  final String authorId; // <-- ADD THIS
  final int replyCount;
  final Timestamp lastActivity;
  final String lastActivityBy;

  ForumThread({
    required this.id,
    required this.title,
    required this.category,
    required this.authorName,
    required this.authorId, // <-- ADD THIS
    required this.replyCount,
    required this.lastActivity,
    required this.lastActivityBy,
  });

  // Factory constructor to create a ForumThread from a Firestore document
  factory ForumThread.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ForumThread(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      category: data['category'] ?? 'Uncategorized',
      authorName: data['authorName'] ?? 'Unknown',
      authorId: data['authorId'] ?? '', // <-- ADD THIS
      replyCount: data['replyCount'] ?? 0,
      lastActivity: data['lastActivity'] ?? Timestamp.now(),
      lastActivityBy: data['lastActivityBy'] ?? 'Unknown',
    );
  }
}