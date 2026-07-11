import '../../core/utils/market_symbol_utils.dart';
import '../../data/models/market_quote.dart';
import '../../data/models/news_article.dart';
import '../../data/models/watchlist_item.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/services/market_data_api_service.dart';

class AnalysisService {
  AnalysisService({
    required PortfolioRepository portfolioRepository,
    required MarketDataApiService marketDataApiService,
    required NewsRepository newsRepository,
  }) : _portfolioRepository = portfolioRepository,
       _marketDataApiService = marketDataApiService,
       _newsRepository = newsRepository;

  final PortfolioRepository _portfolioRepository;
  final MarketDataApiService _marketDataApiService;
  final NewsRepository _newsRepository;

  Future<AnalysisDashboardData> loadDashboard() async {
    final PortfolioOverview overview = await _portfolioRepository
        .getPortfolioOverview();
    final List<WatchlistItem> watchlist = await _portfolioRepository
        .getWatchlist();
    final List<String> trackedSymbols = mergeTrackedSymbols(
      overview.positions,
      watchlist,
    );

    bool newsConnected = false;
    bool marketAttemptFailed = false;
    bool newsAttemptFailed = false;
    List<NewsArticle> latestNews = const <NewsArticle>[];
    Map<String, MarketQuote> marketQuotes = const <String, MarketQuote>{};
    String? marketStatusMessage;

    try {
      latestNews = await _newsRepository.getNews(limit: 6);
      newsConnected = true;
    } catch (_) {
      newsAttemptFailed = true;
    }

    if (trackedSymbols.isNotEmpty) {
      try {
        final MarketQuotesResponse response = await _marketDataApiService
            .getQuotesResult(
              trackedSymbols
                  .map(normalizeMarketSymbolForBackend)
                  .toList(growable: false),
            );
        marketQuotes = response.quotes;
        if (!response.backendReachable) {
          marketAttemptFailed = true;
          marketStatusMessage =
              'Server MoneyPilot belum dapat dihubungi. Data lokal tetap tersedia.';
        } else if (response.hasProviderErrors && marketQuotes.isEmpty) {
          marketStatusMessage =
              'Data pasar belum tersedia. Portofolio lokal tetap dapat digunakan.';
        }
      } catch (_) {
        marketAttemptFailed = true;
      }
    }

    final Map<String, WatchlistItem> watchlistBySymbol =
        <String, WatchlistItem>{
          for (final WatchlistItem item in watchlist) item.symbol: item,
        };
    final Map<String, PortfolioPositionSummary> positionBySymbol =
        <String, PortfolioPositionSummary>{
          for (final PortfolioPositionSummary item in overview.positions)
            item.symbol: item,
        };

    final List<AnalysisTrackedSymbol> trackedItems = trackedSymbols
        .map((String symbol) {
          final PortfolioPositionSummary? position = positionBySymbol[symbol];
          final WatchlistItem? watchlistItem = watchlistBySymbol[symbol];
          final String companyName =
              position?.companyName ?? watchlistItem?.companyName ?? symbol;
          final List<NewsArticle> relatedNews = filterNewsForSymbol(
            latestNews,
            symbol: symbol,
            companyName: companyName,
          );
          final MarketQuote? marketQuote =
              marketQuotes[normalizeMarketSymbolForBackend(symbol)] ??
              marketQuotes[symbol];

          return AnalysisTrackedSymbol(
            symbol: symbol,
            companyName: companyName,
            position: position,
            watchlistItem: watchlistItem,
            marketQuote: marketQuote,
            relatedNews: relatedNews,
            insights: buildEducationalInsights(
              symbol: symbol,
              companyName: companyName,
              position: position,
              watchlistItem: watchlistItem,
              marketQuote: marketQuote,
              relatedNews: relatedNews,
            ),
          );
        })
        .toList(growable: false);

    final bool backendUnavailable = marketAttemptFailed || newsAttemptFailed;
    final bool backendConnected =
        (newsConnected || marketQuotes.isNotEmpty || trackedSymbols.isEmpty) &&
        !backendUnavailable;
    final String backendStatusMessage;
    if (!backendConnected) {
      backendStatusMessage =
          marketStatusMessage ??
          'Server MoneyPilot belum dapat dihubungi. Data lokal tetap tersedia.';
    } else if (marketStatusMessage != null) {
      backendStatusMessage = marketStatusMessage;
    } else if (!newsConnected) {
      backendStatusMessage =
          'Data portofolio dan watchlist lokal siap. Berita terbaru belum tersedia saat ini.';
    } else if (trackedItems.isEmpty) {
      backendStatusMessage =
          'Data lokal siap. Tambahkan saham ke portofolio atau watchlist untuk melihat analisis yang lebih lengkap.';
    } else {
      backendStatusMessage =
          'Data lokal, harga pasar, dan berita terbaru berhasil dimuat.';
    }

    return AnalysisDashboardData(
      overview: overview,
      watchlist: watchlist,
      trackedItems: trackedItems,
      latestNews: latestNews,
      backendConnected: backendConnected,
      backendStatusMessage: backendStatusMessage,
    );
  }

  Future<AnalysisSymbolDetailData> loadSymbolDetail(String symbol) async {
    final String normalizedSymbol = symbol.trim().toUpperCase();
    final PortfolioOverview overview = await _portfolioRepository
        .getPortfolioOverview();
    final WatchlistItem? watchlistItem = await _portfolioRepository
        .getActiveWatchlistItemBySymbol(normalizedSymbol);
    PortfolioPositionSummary? position;
    for (final PortfolioPositionSummary item in overview.positions) {
      if (item.symbol == normalizedSymbol) {
        position = item;
        break;
      }
    }

    List<NewsArticle> relatedNews = const <NewsArticle>[];
    bool backendUnavailable = false;

    final MarketQuoteResponse marketQuoteResponse = await _marketDataApiService
        .getQuoteResult(normalizeMarketSymbolForBackend(normalizedSymbol));
    final MarketQuote? marketQuote = marketQuoteResponse.quote;
    try {
      relatedNews = await _newsRepository.getRelatedNews(
        normalizedSymbol,
        companyName: position?.companyName ?? watchlistItem?.companyName,
      );
    } catch (_) {
      backendUnavailable = true;
    }

    final String companyName =
        position?.companyName ?? watchlistItem?.companyName ?? normalizedSymbol;

    String? backendStatusMessage;
    if (!marketQuoteResponse.backendReachable || backendUnavailable) {
      backendStatusMessage =
          'Server MoneyPilot belum dapat dihubungi. Data lokal tetap tersedia.';
    } else if (marketQuote == null && marketQuoteResponse.backendReachable) {
      backendStatusMessage =
          marketQuoteResponse.message ??
          'Data pasar belum tersedia. Portofolio lokal tetap dapat digunakan.';
    }

    return AnalysisSymbolDetailData(
      symbol: normalizedSymbol,
      companyName: companyName,
      position: position,
      watchlistItem: watchlistItem,
      marketQuote: marketQuote,
      relatedNews: relatedNews,
      backendStatusMessage: backendStatusMessage,
      insights: buildEducationalInsights(
        symbol: normalizedSymbol,
        companyName: companyName,
        position: position,
        watchlistItem: watchlistItem,
        marketQuote: marketQuote,
        relatedNews: relatedNews,
      ),
    );
  }

  static List<String> mergeTrackedSymbols(
    List<PortfolioPositionSummary> positions,
    List<WatchlistItem> watchlist,
  ) {
    final Set<String> merged = <String>{};
    for (final PortfolioPositionSummary position in positions) {
      merged.add(position.symbol.trim().toUpperCase());
    }
    for (final WatchlistItem item in watchlist) {
      merged.add(item.symbol.trim().toUpperCase());
    }
    final List<String> result = merged.toList(growable: false)..sort();
    return result;
  }

  static List<NewsArticle> filterNewsForSymbol(
    List<NewsArticle> articles, {
    required String symbol,
    required String companyName,
  }) {
    final String normalizedSymbol = symbol.trim().toUpperCase();
    final String normalizedCompanyName = companyName.trim().toUpperCase();

    return articles
        .where((NewsArticle article) {
          final String haystack =
              '${article.title} ${article.summary} ${article.category}'
                  .toUpperCase();
          return haystack.contains(normalizedSymbol) ||
              (normalizedCompanyName.isNotEmpty &&
                  haystack.contains(normalizedCompanyName));
        })
        .toList(growable: false);
  }

  static List<String> buildEducationalInsights({
    required String symbol,
    required String companyName,
    required PortfolioPositionSummary? position,
    required WatchlistItem? watchlistItem,
    required MarketQuote? marketQuote,
    required List<NewsArticle> relatedNews,
  }) {
    final List<String> insights = <String>[];

    if (position != null && watchlistItem != null) {
      insights.add(
        'Saham ini ada di portofolio dan watchlist, sehingga cocok dipantau bersama data pasar dan berita terbaru.',
      );
    } else if (position != null) {
      insights.add(
        'Saham ini sudah ada di portofolio. Pantau pergerakan harga dan berita untuk memahami konteksnya lebih lanjut.',
      );
    } else if (watchlistItem != null) {
      insights.add(
        'Saham ini ada di watchlist, tetapi belum ada transaksi di portofolio.',
      );
    }

    if (position != null && marketQuote != null) {
      if (marketQuote.price >= position.averageBuyPrice) {
        insights.add(
          'Harga pasar saat ini berada di atas harga rata-rata portofolio. Evaluasi lebih lanjut tetap diperlukan.',
        );
      } else {
        insights.add(
          'Harga pasar saat ini berada di bawah harga rata-rata portofolio. Analisis tambahan tetap diperlukan sebelum mengambil keputusan pribadi.',
        );
      }
    } else if (position != null) {
      insights.add(
        'Data pasar belum tersedia. Analisis saat ini hanya berdasarkan data lokal portofolio.',
      );
    }

    if (watchlistItem?.targetPrice != null) {
      insights.add(
        'Watchlist memiliki target harga pribadi sebagai catatan pemantauan, bukan sebagai rekomendasi investasi.',
      );
    }

    if (relatedNews.isNotEmpty) {
      insights.add(
        'Ada beberapa berita terbaru yang dapat dibaca untuk memahami konteks pasar.',
      );
    } else {
      insights.add(
        'Belum ada berita terkait yang terdeteksi saat ini. Pemantauan dapat dilanjutkan dari data lokal.',
      );
    }

    return insights;
  }
}

class AnalysisDashboardData {
  const AnalysisDashboardData({
    required this.overview,
    required this.watchlist,
    required this.trackedItems,
    required this.latestNews,
    required this.backendConnected,
    required this.backendStatusMessage,
  });

  final PortfolioOverview overview;
  final List<WatchlistItem> watchlist;
  final List<AnalysisTrackedSymbol> trackedItems;
  final List<NewsArticle> latestNews;
  final bool backendConnected;
  final String backendStatusMessage;
}

class AnalysisTrackedSymbol {
  const AnalysisTrackedSymbol({
    required this.symbol,
    required this.companyName,
    required this.position,
    required this.watchlistItem,
    required this.marketQuote,
    required this.relatedNews,
    required this.insights,
  });

  final String symbol;
  final String companyName;
  final PortfolioPositionSummary? position;
  final WatchlistItem? watchlistItem;
  final MarketQuote? marketQuote;
  final List<NewsArticle> relatedNews;
  final List<String> insights;

  bool get isInPortfolio => position != null;
  bool get isInWatchlist => watchlistItem != null;
}

class AnalysisSymbolDetailData {
  const AnalysisSymbolDetailData({
    required this.symbol,
    required this.companyName,
    required this.position,
    required this.watchlistItem,
    required this.marketQuote,
    required this.relatedNews,
    required this.backendStatusMessage,
    required this.insights,
  });

  final String symbol;
  final String companyName;
  final PortfolioPositionSummary? position;
  final WatchlistItem? watchlistItem;
  final MarketQuote? marketQuote;
  final List<NewsArticle> relatedNews;
  final String? backendStatusMessage;
  final List<String> insights;

  bool get isInPortfolio => position != null;
  bool get isInWatchlist => watchlistItem != null;
}
