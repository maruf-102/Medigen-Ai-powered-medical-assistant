// This enum tells our list what type of result this is
enum SearchResultType { doctor, article, forum }

class SearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String documentId; // The ID of the doc
  final dynamic originalObject; // The actual Doctor, Article, or Thread

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.documentId,
    required this.originalObject,
  });
}