import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/news_article.dart';
import '../models/news_impact_analysis.dart';

class NewsApiService {
  NewsApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConstants.defaultBackendBaseUrl).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<List<NewsArticle>> fetchNews({
    String? category,
    String? query,
    int limit = 10,
  }) async {
    if (_baseUrl.isEmpty) {
      throw AppException('Base URL backend belum diatur.');
    }

    final Uri uri = Uri.parse('$_baseUrl/api/news').replace(
      queryParameters: <String, String>{
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'limit': '$limit',
      },
    );

    final http.Response response = await _safeSend(() => _client.get(uri));
    final Map<String, dynamic> payload = _decodePayload(response);
    final List<dynamic> rawData =
        payload['data'] as List<dynamic>? ?? <dynamic>[];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromJson)
        .toList(growable: false);
  }

  Future<NewsArticle> fetchNewsDetail(String newsId) async {
    final Uri uri = Uri.parse('$_baseUrl/api/news/$newsId');
    final http.Response response = await _safeSend(() => _client.get(uri));
    final Map<String, dynamic> payload = _decodePayload(response);
    final Map<String, dynamic> data =
        payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return NewsArticle.fromJson(data);
  }

  Future<NewsImpactAnalysis> analyzeNews(NewsArticle article) async {
    final Uri uri = Uri.parse('$_baseUrl/api/news/analyze');
    final http.Response response = await _safeSend(
      () => _client.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'newsId': article.id,
          'title': article.title,
          'summary': article.summary,
          'url': article.url,
          'category': article.category,
        }),
      ),
    );
    final Map<String, dynamic> payload = _decodePayload(response);
    final Map<String, dynamic> data =
        payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return NewsImpactAnalysis.fromJson(data);
  }

  Future<http.Response> _safeSend(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (_) {
      throw AppException(
        'Server MoneyPilot belum dapat dihubungi. Fitur lokal tetap bisa digunakan.',
      );
    }
  }

  Map<String, dynamic> _decodePayload(http.Response response) {
    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || payload['status'] == 'error') {
      final Map<String, dynamic> error =
          payload['error'] as Map<String, dynamic>? ?? <String, dynamic>{};
      throw AppException(
        (payload['message'] as String?) ?? 'Permintaan berita gagal diproses.',
        code: error['code'] as String?,
        statusCode: error['statusCode'] as int? ?? response.statusCode,
      );
    }
    return payload;
  }
}
