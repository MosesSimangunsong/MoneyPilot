import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/app_setting.dart';
import '../../data/models/money_transaction.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/sync_status_indicator.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({
    super.key,
    required this.sessionController,
    required this.appSettingRepository,
    required this.categoryRepository,
    required this.syncRepository,
    required this.transactionRepository,
  });

  final AppSessionController sessionController;
  final AppSettingRepository appSettingRepository;
  final CategoryRepository categoryRepository;
  final SyncRepository syncRepository;
  final TransactionRepository transactionRepository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionController,
      builder: (BuildContext context, Widget? child) {
        return StreamBuilder<void>(
          stream: transactionRepository.watchTransactions(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return FutureBuilder<_BerandaViewData>(
              future: _loadViewData(),
              builder: (BuildContext context, AsyncSnapshot<_BerandaViewData> snapshot) {
                final _BerandaViewData? data = snapshot.data;
                return AppPage(
                  title: 'Halo, ${sessionController.userName}',
                  description:
                      'Ringkasan uang bulan ini dirangkum dari data lokal MoneyPilot.',
                  actions: <Widget>[
                    IconButton(
                      tooltip: 'Pengaturan sync',
                      onPressed: () => context.push(RouteConstants.settings),
                      icon: const Icon(LucideIcons.settings2),
                    ),
                    IconButton(
                      tooltip: 'Info keamanan',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              sessionController.biometricSupported
                                  ? 'Biometric ${sessionController.biometricEnabled ? 'aktif' : 'nonaktif'} untuk aplikasi ini.'
                                  : 'Perangkat ini belum mendukung biometric.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.shield),
                    ),
                  ],
                  children: <Widget>[
                    _MonthlyOverview(summary: data?.summary),
                    const SizedBox(height: AppSpacing.lg),
                    StreamBuilder<void>(
                      stream: appSettingRepository.watchSettings(),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<void> settingsSnapshot,
                          ) {
                            return FutureBuilder<_SyncOverviewData>(
                              future: _loadSyncOverview(),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<_SyncOverviewData> snapshot,
                                  ) {
                                    final _SyncOverviewData? syncData =
                                        snapshot.data;
                                    return _InfoBlock(
                                      title: 'Status sync spreadsheet',
                                      description: syncData == null
                                          ? 'Memuat status sinkronisasi terbaru.'
                                          : syncData.description,
                                      trailing: syncData == null
                                          ? null
                                          : SyncStatusIndicator(
                                              status: syncData.status,
                                              pendingCount:
                                                  syncData.pendingCount,
                                            ),
                                    );
                                  },
                            );
                          },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: <Widget>[
                        Text(
                          'Transaksi terbaru',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/keuangan'),
                          child: const Text('Lihat semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        data == null)
                      const Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      const _InfoBlock(
                        title: 'Ringkasan belum bisa dimuat',
                        description:
                            'Coba buka lagi beberapa saat lagi. Data lokal aplikasi mungkin masih disiapkan.',
                      )
                    else if (data == null || data.summary.isEmpty)
                      const _InfoBlock(
                        title: 'Belum ada transaksi bulan ini',
                        description:
                            'Tambahkan transaksi dari tab Keuangan agar beranda mulai menampilkan arus kas dan riwayat terbaru.',
                      )
                    else
                      ..._buildRecentTransactions(
                        data.summary.recentTransactions,
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    FutureBuilder<int>(
                      future: categoryRepository.countActiveCategories(),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<int> categorySnapshot,
                          ) {
                            final int totalKategori =
                                categorySnapshot.data ?? 0;
                            return _InfoBlock(
                              title: 'Kategori aktif',
                              description:
                                  '$totalKategori kategori aktif siap dipakai untuk pencatatan transaksi manual.',
                            );
                          },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<_BerandaViewData> _loadViewData() async {
    final MonthlyTransactionSummary summary = await transactionRepository
        .getMonthlySummary(DateTime.now().toUtc());
    return _BerandaViewData(summary: summary);
  }

  Future<_SyncOverviewData> _loadSyncOverview() async {
    final AppSetting settings = await appSettingRepository
        .getOrCreateSettings();
    final int pendingCount = await syncRepository.countUnsyncedItems();
    final String status =
        settings.lastSpreadsheetSyncStatus?.trim().isNotEmpty == true
        ? settings.lastSpreadsheetSyncStatus!.trim()
        : (pendingCount > 0 ? 'pending' : 'belum');
    final String description = settings.lastSpreadsheetSyncAt == null
        ? pendingCount > 0
              ? '$pendingCount item menunggu sinkronisasi ke spreadsheet.'
              : 'Belum ada riwayat sync. Buka Settings untuk menghubungkan Google Apps Script.'
        : 'Sync terakhir ${DateFormatter.formatDateTime(settings.lastSpreadsheetSyncAt!)}. ${pendingCount > 0 ? '$pendingCount item masih menunggu sync.' : 'Semua perubahan lokal sudah terkirim.'}';
    return _SyncOverviewData(
      status: status,
      pendingCount: pendingCount,
      description: description,
    );
  }

  List<Widget> _buildRecentTransactions(List<MoneyTransaction> transactions) {
    return <Widget>[
      for (int index = 0; index < transactions.length; index++) ...<Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          title: Text(transactions[index].title),
          subtitle: Text(
            '${transactions[index].categoryNameSnapshot} - ${DateFormatter.formatShortDate(transactions[index].transactionDate)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Text(
            '${transactions[index].type == 'income' ? '+' : '-'}${CurrencyFormatter.formatRupiah(transactions[index].amount)}',
            style: TextStyle(
              color: transactions[index].type == 'income'
                  ? AppColors.success
                  : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (index < transactions.length - 1) const Divider(height: 1),
      ],
    ];
  }
}

class _MonthlyOverview extends StatelessWidget {
  const _MonthlyOverview({required this.summary});

  final MonthlyTransactionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final MonthlyTransactionSummary data =
        summary ??
        MonthlyTransactionSummary(
          month: DateTime.now().toUtc(),
          incomeTotal: 0,
          expenseTotal: 0,
          transactionCount: 0,
          recentTransactions: const <MoneyTransaction>[],
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ringkasan ${DateFormatter.formatMonthYear(data.month)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: <Widget>[
              _MetricColumn(
                label: 'Pemasukan',
                value: CurrencyFormatter.formatRupiah(data.incomeTotal),
                color: AppColors.success,
              ),
              _MetricColumn(
                label: 'Pengeluaran',
                value: CurrencyFormatter.formatRupiah(data.expenseTotal),
                color: AppColors.danger,
              ),
              _MetricColumn(
                label: 'Sisa cashflow',
                value: CurrencyFormatter.formatRupiah(data.cashflow),
                color: data.cashflow >= 0
                    ? AppColors.primaryDark
                    : AppColors.danger,
              ),
              _MetricColumn(
                label: 'Jumlah transaksi',
                value: '${data.transactionCount}',
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
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
      width: 140,
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.description,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
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

class _BerandaViewData {
  const _BerandaViewData({required this.summary});

  final MonthlyTransactionSummary summary;
}

class _SyncOverviewData {
  const _SyncOverviewData({
    required this.status,
    required this.pendingCount,
    required this.description,
  });

  final String status;
  final int pendingCount;
  final String description;
}
