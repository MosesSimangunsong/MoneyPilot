class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.category,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final String category;
  final DateTime publishedAt;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      source: (json['source'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? 'Global').trim(),
      publishedAt: DateTime.parse(
        (json['publishedAt'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }
}
