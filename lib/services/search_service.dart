import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medigen/models/article_model.dart';
import 'package:medigen/models/doctor_model.dart';
import 'package:medigen/models/forum_thread_model.dart';
import 'package:medigen/models/search_result_model.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Main Search Function ---
  Future<List<SearchResult>> searchAll(String query) async {
    final String lowercaseQuery = query.toLowerCase();

    // 1. Run all searches in parallel
    final results = await Future.wait([
      _searchDoctors(lowercaseQuery),
      _searchArticles(lowercaseQuery),
      _searchForumThreads(lowercaseQuery),
    ]);

    // 2. Flatten the lists from all searches into one list
    final List<SearchResult> mergedList = results.expand((list) => list).toList();

    // 3. (Optional) Sort the merged list. We can add this later.
    mergedList.shuffle(); // For now, just shuffle them

    return mergedList;
  }

  // --- Search for Doctors ---
  Future<List<SearchResult>> _searchDoctors(String query) async {
    final snapshot = await _db.collection('doctors').get();
    return snapshot.docs
        .map((doc) => Doctor.fromFirestore(doc))
        .where((doctor) {
      return doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query);
    })
        .map((doctor) => SearchResult(
      title: doctor.name,
      subtitle: doctor.specialty,
      type: SearchResultType.doctor,
      documentId: doctor.id,
      originalObject: doctor,
    ))
        .toList();
  }

  // --- Search for Articles ---
  Future<List<SearchResult>> _searchArticles(String query) async {
    final snapshot = await _db.collection('articles').get();
    return snapshot.docs
        .map((doc) => Article.fromFirestore(doc))
        .where((article) {
      return article.title.toLowerCase().contains(query) ||
          article.category.toLowerCase().contains(query);
    })
        .map((article) => SearchResult(
      title: article.title,
      subtitle: 'Article in ${article.category}',
      type: SearchResultType.article,
      documentId: article.id,
      originalObject: article,
    ))
        .toList();
  }

  // --- Search for Forum Threads ---
  Future<List<SearchResult>> _searchForumThreads(String query) async {
    final snapshot = await _db.collection('forumThreads').get();
    return snapshot.docs
        .map((doc) => ForumThread.fromFirestore(doc))
        .where((thread) {
      return thread.title.toLowerCase().contains(query) ||
          thread.category.toLowerCase().contains(query);
    })
        .map((thread) => SearchResult(
      title: thread.title,
      subtitle: 'Forum: ${thread.category}',
      type: SearchResultType.forum,
      documentId: thread.id,
      originalObject: thread,
    ))
        .toList();
  }
}