import '../../data/models/news_article.dart';
import '../../data/models/news_impact_analysis.dart';
import '../services/news_api_service.dart';

class NewsRepository {
  NewsRepository(this._newsApiService);

  final NewsApiService _newsApiService;

  Future<List<NewsArticle>> getNews({
    String? category,
    String? query,
    int limit = 10,
  }) {
    return _newsApiService.fetchNews(
      category: category,
      query: query,
      limit: limit,
    );
  }

  Future<List<NewsArticle>> getRelatedNews(
    String symbol, {
    String? companyName,
    int limit = 6,
  }) {
    final String normalizedSymbol = symbol.trim().toUpperCase();
    final String normalizedCompanyName = companyName?.trim() ?? '';
    final String query = normalizedCompanyName.isEmpty
        ? normalizedSymbol
        : '$normalizedSymbol $normalizedCompanyName';
    return _newsApiService.fetchNews(query: query, limit: limit);
  }

  Future<NewsArticle> getNewsDetail(String newsId) {
    return _newsApiService.fetchNewsDetail(newsId);
  }

  Future<NewsImpactAnalysis> analyzeNews(NewsArticle article) {
    return _newsApiService.analyzeNews(article);
  }
}
