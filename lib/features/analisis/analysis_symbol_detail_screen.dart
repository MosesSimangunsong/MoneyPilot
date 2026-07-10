import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/market_quote.dart';
import '../../data/models/news_article.dart';
import '../../data/models/watchlist_item.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/services/market_data_api_service.dart';
import '../../shared/layouts/app_page.dart';
import '../berita/berita_screen.dart';
import 'analysis_service.dart';
import 'watchlist_form_dialog.dart';

class AnalysisSymbolDetailScreen extends StatefulWidget {
  const AnalysisSymbolDetailScreen({
    super.key,
    required this.symbol,
    required this.portfolioRepository,
    required this.marketDataApiService,
    required this.newsRepository,
  });

  final String symbol;
  final PortfolioRepository portfolioRepository;
  final MarketDataApiService marketDataApiService;
  final NewsRepository newsRepository;

  @override
  State<AnalysisSymbolDetailScreen> createState() =>
      _AnalysisSymbolDetailScreenState();
}

class _AnalysisSymbolDetailScreenState
    extends State<AnalysisSymbolDetailScreen> {
  late final AnalysisService _analysisService;
  late Future<AnalysisSymbolDetailData> _future;

  @override
  void initState() {
    super.initState();
    _analysisService = AnalysisService(
      portfolioRepository: widget.portfolioRepository,
      marketDataApiService: widget.marketDataApiService,
      newsRepository: widget.newsRepository,
    );
    _future = _analysisService.loadSymbolDetail(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalysisSymbolDetailData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AnalysisSymbolDetailData> snapshot) {
        final AnalysisSymbolDetailData? data = snapshot.data;
        return AppPage(
          title: data?.symbol ?? widget.symbol.toUpperCase(),
          description:
              data?.companyName ??
              'Analisis ini bersifat edukatif dan bukan rekomendasi investasi.',
          actions: <Widget>[
            IconButton(
              onPressed: _refresh,
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
          children: <Widget>[
            const _DetailDisclaimerCard(),
            const SizedBox(height: AppSpacing.lg),
            if (snapshot.connectionState == ConnectionState.waiting &&
                data == null)
              const _DetailSectionCard(
                title: 'Menyiapkan detail analisis',
                description:
                    'MoneyPilot sedang memuat data lokal dan informasi pasar yang tersedia.',
              )
            else if (snapshot.hasError && data == null)
              _DetailSectionCard(
                title: 'Detail analisis belum bisa dimuat',
                description: 'Coba muat ulang lagi dari halaman Analisis.',
                action: OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('Muat Ulang'),
                ),
              )
            else if (data != null) ...<Widget>[
              if (data.backendStatusMessage != null) ...<Widget>[
                _DetailSectionCard(
                  title: 'Server belum terhubung',
                  description: data.backendStatusMessage!,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _DetailSectionCard(
                title: 'Status',
                description: _buildStatusText(data),
                action: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    if (data.isInWatchlist)
                      OutlinedButton(
                        onPressed: () => _editWatchlist(data.watchlistItem!),
                        child: const Text('Edit Watchlist'),
                      )
                    else
                      FilledButton(
                        onPressed: () => _createWatchlist(data),
                        child: const Text('Tambah ke Watchlist'),
                      ),
                    TextButton(
                      onPressed: () => context.go(RouteConstants.berita),
                      child: const Text('Buka Berita Terkait'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailMetricsCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              _DetailSectionCard(
                title: 'Insight Edukatif',
                description: data.insights
                    .map((String item) => '- $item')
                    .join('\n'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailSectionCard(
                title: 'Berita Terkait',
                description: data.relatedNews.isEmpty
                    ? 'Belum ada berita terkait yang berhasil dimuat untuk symbol ini.'
                    : '',
                child: data.relatedNews.isEmpty
                    ? null
                    : Column(
                        children: data.relatedNews
                            .map(
                              (NewsArticle article) => _DetailNewsTile(
                                article: article,
                                onTap: () => _openNewsDetail(article),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _buildStatusText(AnalysisSymbolDetailData data) {
    if (data.isInPortfolio && data.isInWatchlist) {
      return 'Saham ini ada di portofolio dan watchlist.';
    }
    if (data.isInPortfolio) {
      return 'Saham ini ada di portofolio.';
    }
    if (data.isInWatchlist) {
      return 'Saham ini ada di watchlist.';
    }
    return 'Saham ini belum ada di portofolio maupun watchlist.';
  }

  Future<void> _createWatchlist(AnalysisSymbolDetailData data) async {
    final WatchlistFormValue? value = await WatchlistFormDialog.show(
      context,
      initialSymbol: data.symbol,
    );
    if (value == null) {
      return;
    }
    await widget.portfolioRepository.createWatchlistItem(
      symbol: value.symbol,
      companyName: value.companyName.isEmpty
          ? data.companyName
          : value.companyName,
      targetPrice: value.targetPrice,
      note: value.note,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watchlist berhasil ditambahkan.')),
    );
    setState(() {
      _future = _analysisService.loadSymbolDetail(widget.symbol);
    });
  }

  Future<void> _editWatchlist(WatchlistItem item) async {
    final WatchlistFormValue? value = await WatchlistFormDialog.show(
      context,
      initialItem: item,
    );
    if (value == null) {
      return;
    }
    await widget.portfolioRepository.updateWatchlistItem(
      item.uuid,
      symbol: value.symbol,
      companyName: value.companyName,
      targetPrice: value.targetPrice,
      note: value.note,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watchlist berhasil disimpan.')),
    );
    _refresh();
  }

  Future<void> _openNewsDetail(NewsArticle article) async {
    await context.push(
      RouteConstants.beritaDetail,
      extra: NewsRouteArguments(article: article),
    );
  }

  void _refresh() {
    setState(() {
      _future = _analysisService.loadSymbolDetail(widget.symbol);
    });
  }
}

class _DetailDisclaimerCard extends StatelessWidget {
  const _DetailDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Analisis ini bersifat edukatif dan bukan rekomendasi investasi.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailMetricsCard extends StatelessWidget {
  const _DetailMetricsCard({required this.data});

  final AnalysisSymbolDetailData data;

  @override
  Widget build(BuildContext context) {
    final double totalShares = data.position?.totalShares.toDouble() ?? 0;
    final double totalMarketValue =
        totalShares * (data.marketQuote?.price ?? 0);
    final double totalCost = data.position?.totalCost ?? 0;
    final double estimatedGainLoss = totalMarketValue - totalCost;

    return _DetailSectionCard(
      title: 'Ringkasan Symbol',
      description: '',
      action: data.marketQuote == null
          ? null
          : Text(
              _buildDetailMarketCaption(data.marketQuote!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: <Widget>[
          _DetailMetric(
            label: 'Total lot',
            value: data.position == null ? '0' : '${data.position!.totalLot}',
          ),
          _DetailMetric(
            label: 'Total shares',
            value: data.position == null
                ? '0'
                : '${data.position!.totalShares}',
          ),
          _DetailMetric(
            label: 'Harga rata-rata',
            value: data.position == null
                ? 'Data Lokal'
                : CurrencyFormatter.formatRupiah(
                    data.position!.averageBuyPrice,
                  ),
          ),
          _DetailMetric(
            label: 'Total modal',
            value: data.position == null
                ? 'Data Lokal'
                : CurrencyFormatter.formatRupiah(data.position!.totalCost),
          ),
          _DetailMetric(
            label: 'Harga Pasar',
            value: data.marketQuote == null
                ? 'Data Lokal'
                : CurrencyFormatter.formatRupiah(data.marketQuote!.price),
          ),
          if (data.marketQuote != null)
            _DetailMetric(
              label: 'Sumber Data',
              value: data.marketQuote!.sourceLabel,
            ),
          _DetailMetric(
            label: 'Nilai Pasar',
            value: data.marketQuote == null
                ? 'Data Lokal'
                : CurrencyFormatter.formatRupiah(totalMarketValue),
          ),
          _DetailMetric(
            label: 'Estimasi Untung/Rugi',
            value: data.marketQuote == null || data.position == null
                ? 'Data Lokal'
                : CurrencyFormatter.formatRupiah(estimatedGainLoss),
            valueColor: data.marketQuote == null || data.position == null
                ? null
                : (estimatedGainLoss >= 0
                      ? AppColors.success
                      : AppColors.warning),
          ),
        ],
      ),
    );
  }
}

String _buildDetailMarketCaption(MarketQuote quote) {
  final List<String> parts = <String>['Sumber: ${quote.sourceLabel}'];
  if (quote.isFallback) {
    parts.add('menggunakan data fallback');
  }
  if (quote.isStale) {
    parts.add('data dapat tertunda');
  }
  if (quote.asOf != null) {
    parts.add('per ${DateFormatter.formatDateTime(quote.asOf!)}');
  } else if (quote.cachedAt != null) {
    parts.add('cache ${DateFormatter.formatDateTime(quote.cachedAt!)}');
  }
  return '${parts.join(' | ')}.\n${quote.message}';
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.description,
    this.action,
    this.child,
  });

  final String title;
  final String description;
  final Widget? action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
          if (child != null) ...<Widget>[
            if (description.isNotEmpty || action != null)
              const SizedBox(height: AppSpacing.lg),
            child!,
          ],
        ],
      ),
    );
  }
}

class _DetailNewsTile extends StatelessWidget {
  const _DetailNewsTile({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              article.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${article.source} - ${DateFormatter.formatDateTime(article.publishedAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
