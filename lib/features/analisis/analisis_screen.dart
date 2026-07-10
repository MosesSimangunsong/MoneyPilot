import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/news_article.dart';
import '../../data/models/market_quote.dart';
import '../../data/models/watchlist_item.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/services/market_data_api_service.dart';
import '../../shared/layouts/app_page.dart';
import '../berita/berita_screen.dart';
import 'analysis_service.dart';
import 'watchlist_form_dialog.dart';

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({
    super.key,
    required this.portfolioRepository,
    required this.marketDataApiService,
    required this.newsRepository,
  });

  final PortfolioRepository portfolioRepository;
  final MarketDataApiService marketDataApiService;
  final NewsRepository newsRepository;

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  late final AnalysisService _analysisService;
  late Future<AnalysisDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _analysisService = AnalysisService(
      portfolioRepository: widget.portfolioRepository,
      marketDataApiService: widget.marketDataApiService,
      newsRepository: widget.newsRepository,
    );
    _future = _analysisService.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalysisDashboardData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AnalysisDashboardData> snapshot) {
        final AnalysisDashboardData? data = snapshot.data;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting && data == null;

        return AppPage(
          title: 'Analisis',
          description:
              'Pantau saham, berita, dan dampak pasar secara edukatif.',
          actions: <Widget>[
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _refresh,
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateWatchlist,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Tambah Watchlist'),
          ),
          children: <Widget>[
            const _DisclaimerCard(),
            const SizedBox(height: AppSpacing.lg),
            if (isLoading)
              const _SectionCard(
                title: 'Menyiapkan analisis',
                description:
                    'MoneyPilot sedang memuat data lokal dan mencoba menghubungi server market secara aman.',
              )
            else if (snapshot.hasError && data == null)
              _RetryCard(
                title: 'Tab Analisis belum bisa dimuat',
                description:
                    'Coba muat ulang lagi. Jika masalah berlanjut, periksa data lokal aplikasi.',
                onRetry: _refresh,
              )
            else if (data != null) ...<Widget>[
              _BackendStatusCard(
                backendConnected: data.backendConnected,
                message: data.backendStatusMessage,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AnalysisSummaryCard(data: data),
              const SizedBox(height: AppSpacing.xl),
              if (data.overview.positions.isEmpty && data.watchlist.isEmpty)
                const _SectionCard(
                  title: 'Belum ada saham untuk dianalisis',
                  description:
                      'Tambahkan saham ke portofolio atau watchlist terlebih dahulu.',
                )
              else ...<Widget>[
                _SectionHeader(
                  title: 'Saham dalam Portofolio',
                  subtitle:
                      'Posisi aktif dari data lokal portofolio beserta konteks harga pasar jika tersedia.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.overview.positions.isEmpty)
                  const _SectionCard(
                    title: 'Portofolio masih kosong',
                    description:
                        'Tambahkan transaksi saham agar analisis posisi bisa ditampilkan di sini.',
                  )
                else
                  ...data.trackedItems
                      .where((AnalysisTrackedSymbol item) => item.isInPortfolio)
                      .map(_buildTrackedSymbolCard),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: 'Watchlist',
                  subtitle:
                      'Saham dipantau secara lokal. Kamu bisa menambah, mengubah catatan, atau menghapusnya kapan saja.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.watchlist.isEmpty)
                  const _SectionCard(
                    title: 'Belum ada saham dipantau',
                    description:
                        'Gunakan tombol Tambah Watchlist untuk mulai memantau symbol yang kamu minati.',
                  )
                else
                  ...data.trackedItems
                      .where((AnalysisTrackedSymbol item) => item.isInWatchlist)
                      .map(_buildTrackedSymbolCard),
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeader(
                  title: 'Berita Terkait',
                  subtitle:
                      'Berita terbaru ditampilkan ringan tanpa analisis AI otomatis.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.latestNews.isEmpty)
                  const _SectionCard(
                    title: 'Berita belum tersedia',
                    description:
                        'Server berita mungkin belum terhubung. Analisis lokal tetap dapat digunakan.',
                  )
                else
                  ...data.latestNews.map(_buildNewsCard),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildTrackedSymbolCard(AnalysisTrackedSymbol item) {
    final double? marketValue =
        item.position == null || item.marketQuote == null
        ? null
        : item.position!.totalShares * item.marketQuote!.price;
    final double? gainLoss = marketValue == null || item.position == null
        ? null
        : marketValue - item.position!.totalCost;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openSymbolDetail(item.symbol),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.symbol,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.companyName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'edit' && item.watchlistItem != null) {
                        _openEditWatchlist(item.watchlistItem!);
                      }
                      if (value == 'delete' && item.watchlistItem != null) {
                        _deleteWatchlist(item.watchlistItem!);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'detail',
                          enabled: false,
                          child: Text('Buka detail analisis'),
                        ),
                        if (item.watchlistItem != null)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit Watchlist'),
                          ),
                        if (item.watchlistItem != null)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Hapus dari Watchlist'),
                          ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _StatusChip(
                    label: item.isInPortfolio
                        ? 'Ada di Portofolio'
                        : 'Belum di Portofolio',
                    backgroundColor: item.isInPortfolio
                        ? AppColors.primarySoft
                        : AppColors.surfaceAlt,
                    foregroundColor: item.isInPortfolio
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  _StatusChip(
                    label: item.isInWatchlist
                        ? 'Ada di Watchlist'
                        : 'Tidak di Watchlist',
                    backgroundColor: item.isInWatchlist
                        ? AppColors.successSoft
                        : AppColors.surfaceAlt,
                    foregroundColor: item.isInWatchlist
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  if (item.position != null)
                    _MetaItem(
                      label: 'Harga rata-rata',
                      value: CurrencyFormatter.formatRupiah(
                        item.position!.averageBuyPrice,
                      ),
                    ),
                  if (item.position != null)
                    _MetaItem(
                      label: 'Total shares',
                      value: '${item.position!.totalShares}',
                    ),
                  _MetaItem(
                    label: 'Harga Pasar',
                    value: item.marketQuote == null
                        ? 'Data lokal'
                        : CurrencyFormatter.formatRupiah(
                            item.marketQuote!.price,
                          ),
                  ),
                  if (item.marketQuote != null)
                    _MetaItem(
                      label: 'Sumber Data',
                      value: item.marketQuote!.sourceLabel,
                    ),
                  _MetaItem(
                    label: 'Berita terkait',
                    value: '${item.relatedNews.length}',
                  ),
                  if (item.watchlistItem?.targetPrice != null)
                    _MetaItem(
                      label: 'Target Harga',
                      value: CurrencyFormatter.formatRupiah(
                        item.watchlistItem!.targetPrice!,
                      ),
                    ),
                  if (gainLoss != null)
                    _MetaItem(
                      label: 'Estimasi Untung/Rugi',
                      value: CurrencyFormatter.formatRupiah(gainLoss),
                      valueColor: gainLoss >= 0
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...item.insights
                  .take(2)
                  .map(
                    (String insight) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        '- $insight',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              if (item.marketQuote != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _buildMarketDataCaption(item.marketQuote!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if ((item.watchlistItem?.note ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Catatan: ${item.watchlistItem!.note!}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openNewsDetail(article),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                article.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${article.source} - ${article.category} - ${DateFormatter.formatDateTime(article.publishedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                article.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateWatchlist() async {
    final WatchlistFormValue? value = await WatchlistFormDialog.show(context);
    if (value == null) {
      return;
    }

    await widget.portfolioRepository.createWatchlistItem(
      symbol: value.symbol,
      companyName: value.companyName,
      targetPrice: value.targetPrice,
      note: value.note,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watchlist berhasil diperbarui.')),
    );
    _refresh();
  }

  Future<void> _openEditWatchlist(WatchlistItem item) async {
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

  Future<void> _deleteWatchlist(WatchlistItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus dari Watchlist?'),
          content: Text(
            '${item.symbol} akan disembunyikan dari daftar watchlist aktif, tetapi tetap tersimpan di data lokal.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.portfolioRepository.softDeleteWatchlistItem(item.uuid);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saham dipindahkan dari Watchlist aktif.')),
    );
    _refresh();
  }

  Future<void> _openSymbolDetail(String symbol) async {
    final Object? changed = await context.push(
      '${RouteConstants.analisis}/symbol/$symbol',
    );
    if (changed == true && mounted) {
      _refresh();
    }
  }

  Future<void> _openNewsDetail(NewsArticle article) async {
    await context.push(
      RouteConstants.beritaDetail,
      extra: NewsRouteArguments(article: article),
    );
  }

  void _refresh() {
    setState(() {
      _future = _analysisService.loadDashboard();
    });
  }
}

String _buildMarketDataCaption(MarketQuote quote) {
  final List<String> parts = <String>['Sumber: ${quote.sourceLabel}'];
  if (quote.isFallback) {
    parts.add('menggunakan data fallback');
  }
  if (quote.isStale) {
    parts.add('data dapat tertunda');
  }
  if (quote.asOf != null) {
    parts.add('per ${DateFormatter.formatDateTime(quote.asOf!)}');
  }
  return '${parts.join(' • ')}.\n${quote.message}';
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Informasi ini bersifat edukatif dan bukan rekomendasi beli atau jual.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.backendConnected,
    required this.message,
  });

  final bool backendConnected;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backendConnected ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            backendConnected ? LucideIcons.serverCog : LucideIcons.serverCrash,
            color: backendConnected ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: backendConnected
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({required this.data});

  final AnalysisDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: <Widget>[
          _MetaItem(
            label: 'Saham di portofolio',
            value: '${data.overview.positions.length}',
          ),
          _MetaItem(
            label: 'Jumlah watchlist',
            value: '${data.watchlist.length}',
          ),
          _MetaItem(
            label: 'Berita terbaru',
            value: '${data.latestNews.length}',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({
    required this.title,
    required this.description,
    required this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onRetry, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, this.valueColor});

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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
