import 'package:app/data/models/news_article.dart';
import 'package:app/data/repositories/news_repository.dart';
import 'package:app/data/services/news_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  test('NewsRepository meneruskan hasil berita dari service', () async {
    final repository = NewsRepository(
      NewsApiService(
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'data': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'news-10',
                  'title': 'Investor memantau rupiah',
                  'summary': 'Ringkasan singkat',
                  'source': 'Mock Source',
                  'url': 'https://example.com/news-10',
                  'category': 'Indonesia',
                  'publishedAt': '2026-07-09T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }),
        baseUrl: 'http://localhost:5000',
      ),
    );

    final List<NewsArticle> articles = await repository.getNews();

    expect(articles.single.category, 'Indonesia');
  });

  test('getRelatedNews tidak memicu endpoint analisis AI otomatis', () async {
    final List<String> requestedPaths = <String>[];
    final repository = NewsRepository(
      NewsApiService(
        client: MockClient((http.Request request) async {
          requestedPaths.add(request.url.path);
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'data': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'news-bbca',
                  'title': 'BBCA dipantau investor',
                  'summary': 'Ringkasan BBCA',
                  'source': 'Mock Source',
                  'url': 'https://example.com/news-bbca',
                  'category': 'Saham',
                  'publishedAt': '2026-07-09T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }),
        baseUrl: 'http://localhost:5000',
      ),
    );

    final List<NewsArticle> articles = await repository.getRelatedNews('BBCA');

    expect(articles, hasLength(1));
    expect(requestedPaths, everyElement('/api/news'));
    expect(requestedPaths, isNot(contains('/api/news/analyze')));
  });
}
