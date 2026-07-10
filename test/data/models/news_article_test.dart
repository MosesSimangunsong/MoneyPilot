import 'package:app/data/models/news_article.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse NewsArticle dari JSON', () {
    final article = NewsArticle.fromJson(<String, dynamic>{
      'id': 'news-1',
      'title': 'Judul berita',
      'summary': 'Ringkasan berita',
      'source': 'Mock Source',
      'url': 'https://example.com',
      'category': 'Global',
      'publishedAt': '2026-07-09T10:00:00Z',
    });

    expect(article.id, 'news-1');
    expect(article.category, 'Global');
    expect(article.publishedAt.toUtc().year, 2026);
  });
}
