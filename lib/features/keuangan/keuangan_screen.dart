import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/app_setting.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/models/money_transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/sync_status_indicator.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({
    super.key,
    required this.appSettingRepository,
    required this.syncRepository,
    required this.transactionRepository,
  });

  final AppSettingRepository appSettingRepository;
  final SyncRepository syncRepository;
  final TransactionRepository transactionRepository;

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.transactionRepository.watchTransactions(),
      builder: (BuildContext context, AsyncSnapshot<void> transactionSnapshot) {
        return FutureBuilder<_KeuanganViewData>(
          future: _loadViewData(),
          builder: (BuildContext context, AsyncSnapshot<_KeuanganViewData> snapshot) {
            final _KeuanganViewData? data = snapshot.data;
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                data == null;

            return AppPage(
              title: 'Keuangan',
              description:
                  'Catat transaksi harianmu secara manual dan lihat arus kas bulan ini.',
              children: <Widget>[
                _SummaryStrip(summary: data?.summary),
                const SizedBox(height: AppSpacing.lg),
                StreamBuilder<void>(
                  stream: widget.appSettingRepository.watchSettings(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<void> settingsSnapshot,
                      ) {
                        return FutureBuilder<_SyncBannerData>(
                          future: _loadSyncBanner(),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<_SyncBannerData> snapshot,
                              ) {
                                final _SyncBannerData? syncData = snapshot.data;
                                if (syncData == null) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          syncData.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      SyncStatusIndicator(
                                        status: syncData.status,
                                        pendingCount: syncData.pendingCount,
                                      ),
                                    ],
                                  ),
                                );
                              },
                        );
                      },
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/keuangan/suara'),
                        icon: const Icon(LucideIcons.mic),
                        label: const Text('Catat suara'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/keuangan/transaksi-baru'),
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('Tambah manual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Filter tipe',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _transactionFilters
                      .map(
                        (_FilterOption option) => ChoiceChip(
                          label: Text(option.label),
                          selected: _selectedFilter == option.value,
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _selectedFilter = option.value;
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  _SectionMessage(
                    title: 'Data transaksi belum bisa ditampilkan',
                    description:
                        'Coba buka kembali halaman ini. Jika masalah berlanjut, periksa data lokal aplikasi.',
                  )
                else if (data == null || data.transactions.isEmpty)
                  _SectionMessage(
                    title: 'Belum ada transaksi',
                    description: _selectedFilter == 'all'
                        ? 'Tambahkan pemasukan atau pengeluaran pertamamu agar ringkasan mulai terisi.'
                        : 'Belum ada transaksi untuk filter ini.',
                  )
                else
                  ..._buildTransactionList(data.transactions),
              ],
            );
          },
        );
      },
    );
  }

  Future<_KeuanganViewData> _loadViewData() async {
    final DateTime month = DateTime.now().toUtc();
    final MonthlyTransactionSummary summary = await widget.transactionRepository
        .getMonthlySummary(month);
    final List<MoneyTransaction> transactions = await widget
        .transactionRepository
        .getActiveTransactions(
          type: _selectedFilter == 'all' ? null : _selectedFilter,
        );

    return _KeuanganViewData(summary: summary, transactions: transactions);
  }

  Future<_SyncBannerData> _loadSyncBanner() async {
    final AppSetting settings = await widget.appSettingRepository
        .getOrCreateSettings();
    final int pendingCount = await widget.syncRepository.countUnsyncedItems();
    final String status =
        settings.lastSpreadsheetSyncStatus?.trim().isNotEmpty == true
        ? settings.lastSpreadsheetSyncStatus!.trim()
        : (pendingCount > 0 ? 'pending' : 'belum');
    final String description = pendingCount > 0
        ? '$pendingCount perubahan lokal siap disinkronkan.'
        : settings.lastSpreadsheetSyncAt == null
        ? 'Belum ada riwayat sync spreadsheet.'
        : 'Spreadsheet terakhir sinkron ${DateFormatter.formatDateTime(settings.lastSpreadsheetSyncAt!)}.';
    return _SyncBannerData(
      status: status,
      pendingCount: pendingCount,
      description: description,
    );
  }

  List<Widget> _buildTransactionList(List<MoneyTransaction> transactions) {
    return <Widget>[
      for (int index = 0; index < transactions.length; index++) ...<Widget>[
        _TransactionListItem(
          transaction: transactions[index],
          onEdit: () => _openEditForm(transactions[index].uuid),
          onDelete: () => _confirmDelete(transactions[index]),
        ),
        if (index < transactions.length - 1) const Divider(height: 1),
      ],
    ];
  }

  Future<void> _openEditForm(String transactionUuid) async {
    await context.push('/keuangan/$transactionUuid/edit');
  }

  Future<void> _confirmDelete(MoneyTransaction transaction) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: Text(
            'Transaksi "${transaction.title}" akan disembunyikan dari daftar aktif, tetapi tetap tersimpan untuk riwayat sinkronisasi.',
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

    await widget.transactionRepository.softDeleteTransaction(transaction.uuid);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi dipindahkan dari daftar aktif.')),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryValue(
                  label: 'Pemasukan',
                  value: CurrencyFormatter.formatRupiah(data.incomeTotal),
                  toneColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryValue(
                  label: 'Pengeluaran',
                  value: CurrencyFormatter.formatRupiah(data.expenseTotal),
                  toneColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.toneColor,
  });

  final String label;
  final String value;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            color: toneColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  const _TransactionListItem({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final MoneyTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'income';
    final Color amountColor = isIncome ? AppColors.success : AppColors.danger;
    final String signedAmount =
        '${isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah(transaction.amount)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      onTap: onEdit,
      title: Text(
        transaction.title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          '${transaction.categoryNameSnapshot} - ${DateFormatter.formatShortDate(transaction.transactionDate)} - ${_paymentMethodLabel(transaction.paymentMethod)}',
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
              value: 'amount',
              enabled: false,
              child: Text(
                signedAmount,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
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
              signedAmount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: amountColor,
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

class _KeuanganViewData {
  const _KeuanganViewData({required this.summary, required this.transactions});

  final MonthlyTransactionSummary summary;
  final List<MoneyTransaction> transactions;
}

class _FilterOption {
  const _FilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _SyncBannerData {
  const _SyncBannerData({
    required this.status,
    required this.pendingCount,
    required this.description,
  });

  final String status;
  final int pendingCount;
  final String description;
}

const List<_FilterOption> _transactionFilters = <_FilterOption>[
  _FilterOption(value: 'all', label: 'Semua'),
  _FilterOption(value: 'income', label: 'Pemasukan'),
  _FilterOption(value: 'expense', label: 'Pengeluaran'),
];

String _paymentMethodLabel(String value) {
  if (value.trim().isEmpty) {
    return 'Tidak Dicatat';
  }
  return value;
}
