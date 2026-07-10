import 'dart:convert';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/data/services/news_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('NewsApiService handle success response', () async {
    final service = NewsApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'news-1',
                'title': 'Judul berita',
                'summary': 'Ringkasan berita',
                'source': 'Mock Source',
                'url': 'https://example.com/news-1',
                'category': 'Global',
                'publishedAt': '2026-07-09T10:00:00Z',
              },
            ],
          }),
          200,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final articles = await service.fetchNews();

    expect(articles, hasLength(1));
    expect(articles.first.title, 'Judul berita');
  });

  test('NewsApiService handle error response', () async {
    final service = NewsApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'message': 'Backend berita gagal.',
            'error': <String, dynamic>{'code': 'NEWS_ERROR', 'statusCode': 503},
          }),
          503,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    expect(service.fetchNews(), throwsA(isA<AppException>()));
  });

  test('NewsApiService aman saat backend unavailable', () async {
    final service = NewsApiService(
      client: MockClient((http.Request request) async {
        throw http.ClientException('network down');
      }),
      baseUrl: 'http://localhost:5000',
    );

    expect(service.fetchNews(), throwsA(isA<AppException>()));
  });
}
