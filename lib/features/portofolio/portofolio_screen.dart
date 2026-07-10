import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/dividend.dart';
import '../../data/models/market_quote.dart';
import '../../data/models/stock_transaction.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/services/market_data_api_service.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class PortofolioScreen extends StatefulWidget {
  const PortofolioScreen({
    super.key,
    required this.portfolioRepository,
    required this.marketDataApiService,
  });

  final PortfolioRepository portfolioRepository;
  final MarketDataApiService marketDataApiService;

  @override
  State<PortofolioScreen> createState() => _PortofolioScreenState();
}

class _PortofolioScreenState extends State<PortofolioScreen> {
  int _refreshNonce = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PortfolioScreenData>(
      key: ValueKey<int>(_refreshNonce),
      future: _loadScreenData(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<_PortfolioScreenData> snapshot,
          ) {
            final PortfolioOverview? data = snapshot.data?.overview;
            final Map<String, MarketQuote> marketQuotes =
                snapshot.data?.marketQuotes ?? const <String, MarketQuote>{};

            return AppPage(
              title: 'Portofolio',
              description:
                  'Catat transaksi saham dan dividen manual, lalu pantau posisi yang masih kamu pegang.',
              children: <Widget>[
                _PortfolioSummaryCard(data: data),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openStockTransactionForm(),
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('Tambah Transaksi Saham'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDividendForm(),
                        icon: const Icon(LucideIcons.wallet),
                        label: const Text('Catat Dividen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const InfoCard(
                  title: 'Sync saham dan dividen belum diaktifkan',
                  description:
                      'Tahap ini memprioritaskan penyimpanan lokal yang stabil. Data portofolio sudah memakai UUID, timestamp UTC, syncStatus, dan soft delete agar siap diaktifkan ke spreadsheet pada tahap berikutnya.',
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Posisi saham',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    data == null)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  const _SectionMessage(
                    title: 'Portofolio belum bisa dimuat',
                    description:
                        'Coba buka kembali halaman ini. Jika masalah berlanjut, periksa data lokal aplikasi.',
                  )
                else if (data == null || data.positions.isEmpty)
                  const _SectionMessage(
                    title: 'Belum ada posisi aktif',
                    description:
                        'Tambahkan transaksi beli saham agar ringkasan posisi mulai terisi.',
                  )
                else ...<Widget>[
                  if (marketQuotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SectionMessage(
                        title: 'Harga pasar belum terhubung',
                        description:
                            'Backend market mungkin belum aktif atau belum dapat dijangkau. Data portofolio lokal tetap aman dan tetap bisa dicatat.',
                      ),
                    ),
                  ...data.positions.map(
                    (PortfolioPositionSummary position) => _PositionCard(
                      position: position,
                      marketQuote:
                          marketQuotes['${position.symbol}.JK'] ??
                          marketQuotes[position.symbol],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Transaksi saham terbaru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data == null || data.recentTransactions.isEmpty)
                  const _SectionMessage(
                    title: 'Belum ada transaksi saham',
                    description:
                        'Transaksi beli dan jual yang kamu catat akan muncul di sini.',
                  )
                else
                  ..._buildTransactionList(data.recentTransactions),
              ],
            );
          },
    );
  }

  Future<_PortfolioScreenData> _loadScreenData() async {
    final PortfolioOverview overview = await widget.portfolioRepository
        .getPortfolioOverview();
    final Map<String, MarketQuote> marketQuotes = await widget
        .marketDataApiService
        .getQuotes(
          overview.positions
              .map((PortfolioPositionSummary item) => '${item.symbol}.JK')
              .toList(growable: false),
        );

    return _PortfolioScreenData(overview: overview, marketQuotes: marketQuotes);
  }

  List<Widget> _buildTransactionList(List<StockTransaction> transactions) {
    return <Widget>[
      for (int index = 0; index < transactions.length; index++) ...<Widget>[
        _StockTransactionTile(
          transaction: transactions[index],
          onEdit: () => _openEditStockTransaction(transactions[index].uuid),
          onDelete: () => _confirmDelete(transactions[index]),
        ),
        if (index < transactions.length - 1) const Divider(height: 1),
      ],
    ];
  }

  Future<void> _openStockTransactionForm() async {
    final Object? result = await context.push(
      RouteConstants.transaksiSahamBaru,
    );
    if (result == true && mounted) {
      setState(() {
        _refreshNonce++;
      });
    }
  }

  Future<void> _openEditStockTransaction(String uuid) async {
    final Object? result = await context.push(
      '${RouteConstants.portofolio}/$uuid/edit',
    );
    if (result == true && mounted) {
      setState(() {
        _refreshNonce++;
      });
    }
  }

  Future<void> _openDividendForm() async {
    final Object? result = await context.push(RouteConstants.catatDividen);
    if (result == true && mounted) {
      setState(() {
        _refreshNonce++;
      });
    }
  }

  Future<void> _confirmDelete(StockTransaction transaction) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus transaksi saham?'),
          content: Text(
            'Transaksi ${transaction.symbol} akan disembunyikan dari daftar aktif, tetapi tetap disimpan untuk riwayat lokal.',
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

    if (confirmed != true || !mounted) {
      return;
    }

    await widget.portfolioRepository.softDeleteStockTransaction(
      transaction.uuid,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _refreshNonce++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi saham dipindahkan dari daftar aktif.'),
      ),
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  const _PortfolioSummaryCard({required this.data});

  final PortfolioOverview? data;

  @override
  Widget build(BuildContext context) {
    final PortfolioOverview overview =
        data ??
        PortfolioOverview(
          totalOwnedStocks: 0,
          totalModal: 0,
          totalDividen: 0,
          positions: const <PortfolioPositionSummary>[],
          recentTransactions: const <StockTransaction>[],
          dividends: const <Dividend>[],
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: <Widget>[
          _SummaryMetric(
            label: 'Saham dimiliki',
            value: '${overview.totalOwnedStocks}',
            color: AppColors.textPrimary,
          ),
          _SummaryMetric(
            label: 'Total modal',
            value: CurrencyFormatter.formatRupiah(overview.totalModal),
            color: AppColors.primaryDark,
          ),
          _SummaryMetric(
            label: 'Total dividen',
            value: CurrencyFormatter.formatRupiah(overview.totalDividen),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position, required this.marketQuote});

  final PortfolioPositionSummary position;
  final MarketQuote? marketQuote;

  @override
  Widget build(BuildContext context) {
    final double? marketValue = marketQuote == null
        ? null
        : marketQuote!.price * position.totalShares;
    final double? gainLoss = marketValue == null
        ? null
        : marketValue - position.totalCost;
    final double? gainLossPercent =
        marketValue == null || position.totalCost == 0
        ? null
        : (gainLoss! / position.totalCost) * 100;
    final Color gainLossColor = (gainLoss ?? 0) >= 0
        ? AppColors.success
        : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    position.symbol,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatRupiah(position.totalCost),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if ((position.companyName ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                position.companyName!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _PositionMeta(
                  label: 'Lot',
                  value: _formatLot(position.totalLot),
                ),
                _PositionMeta(
                  label: 'Lembar',
                  value: '${position.totalShares}',
                ),
                _PositionMeta(
                  label: 'Harga rata-rata',
                  value: CurrencyFormatter.formatRupiah(
                    position.averageBuyPrice,
                  ),
                ),
                _PositionMeta(
                  label: 'Harga Pasar',
                  value: marketQuote == null
                      ? 'Harga pasar belum tersedia'
                      : CurrencyFormatter.formatRupiah(marketQuote!.price),
                ),
                _PositionMeta(
                  label: 'Nilai Pasar',
                  value: marketValue == null
                      ? 'Harga pasar belum tersedia'
                      : CurrencyFormatter.formatRupiah(marketValue),
                ),
                _PositionMeta(
                  label: 'Estimasi Untung/Rugi',
                  value: gainLoss == null
                      ? 'Harga pasar belum tersedia'
                      : '${CurrencyFormatter.formatRupiah(gainLoss)} (${gainLossPercent!.toStringAsFixed(2)}%)',
                  valueColor: gainLoss == null ? null : gainLossColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Data pasar bersifat estimasi dan bukan rekomendasi investasi.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionMeta extends StatelessWidget {
  const _PositionMeta({
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
      width: 120,
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _StockTransactionTile extends StatelessWidget {
  const _StockTransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final StockTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isBuy = transaction.actionType == 'buy';
    final Color toneColor = isBuy ? AppColors.primaryDark : AppColors.warning;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      onTap: onEdit,
      title: Text(
        '${isBuy ? 'Beli' : 'Jual'} ${transaction.symbol}',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          '${_formatLot(transaction.lot.toDouble())} lot - ${transaction.shares} lembar - ${DateFormatter.formatShortDate(transaction.transactionDate)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'edit') {
            onEdit();
            return;
          }
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'price',
              enabled: false,
              child: Text(
                CurrencyFormatter.formatRupiah(transaction.price),
                style: TextStyle(color: toneColor, fontWeight: FontWeight.w700),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit transaksi'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Hapus dari daftar aktif'),
            ),
          ];
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              CurrencyFormatter.formatRupiah(transaction.price),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: toneColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Icon(Icons.more_horiz),
          ],
        ),
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
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

String _formatLot(double lot) {
  if (lot == lot.roundToDouble()) {
    return lot.toStringAsFixed(0);
  }
  return lot.toStringAsFixed(2);
}

class _PortfolioScreenData {
  const _PortfolioScreenData({
    required this.overview,
    required this.marketQuotes,
  });

  final PortfolioOverview overview;
  final Map<String, MarketQuote> marketQuotes;
}
