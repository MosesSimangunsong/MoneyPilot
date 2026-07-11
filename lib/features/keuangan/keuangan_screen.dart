import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/category_icon_mapper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/transaction_date_grouping.dart';
import '../../data/models/money_transaction.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/finance_filter_bar.dart';
import 'widgets/finance_monthly_summary.dart';
import 'widgets/transaction_date_group.dart';

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
          builder:
              (
                BuildContext context,
                AsyncSnapshot<_KeuanganViewData> snapshot,
              ) {
                final _KeuanganViewData? data = snapshot.data;
                final bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    data == null;

                return AppPage(
                  title: 'Keuangan',
                  actions: <Widget>[
                    IconButton(
                      tooltip: 'Kelola kategori',
                      onPressed: () => context.push(RouteConstants.kategori),
                      icon: const Icon(LucideIcons.tags),
                    ),
                  ],
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: _openAddSheet,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Catat transaksi'),
                  ),
                  children: <Widget>[
                    if (data != null)
                      FinanceMonthlySummary(summary: data.summary),
                    if (data != null) const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Filter tipe',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinanceFilterBar(
                      options: _transactionFilters,
                      selectedValue: _selectedFilter,
                      onSelected: (String value) {
                        if (_selectedFilter == value) {
                          return;
                        }
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedSwitcher(
                      duration: AppDurations.normal,
                      child: _buildBody(
                        isLoading: isLoading,
                        snapshot: snapshot,
                        transactionSnapshot: transactionSnapshot,
                        data: data,
                      ),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required AsyncSnapshot<_KeuanganViewData> snapshot,
    required AsyncSnapshot<void> transactionSnapshot,
    required _KeuanganViewData? data,
  }) {
    if (isLoading) {
      return const AppLoadingState(message: 'Memuat transaksi aktif');
    }

    if (snapshot.hasError || transactionSnapshot.hasError) {
      return AppErrorState(
        title: 'Transaksi belum bisa ditampilkan',
        description:
            'Coba muat ulang halaman ini. MoneyPilot akan tetap menjaga data lokalmu.',
        onRetry: () => setState(() {}),
      );
    }

    if (data == null || data.transactions.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.receipt,
        title: _selectedFilter == 'all'
            ? 'Belum ada transaksi'
            : 'Belum ada transaksi untuk filter ini',
        description: _selectedFilter == 'all'
            ? 'Mulai catat pemasukan atau pengeluaran agar MoneyPilot bisa merangkum arus kasmu.'
            : 'Coba ganti filter atau tambahkan transaksi baru dari tombol utama.',
        primaryActionLabel: 'Catat transaksi',
        onPrimaryAction: _openAddSheet,
      );
    }

    final List<TransactionDateGroup> groups =
        TransactionDateGrouping.groupTransactions(data.transactions);

    return Column(
      key: ValueKey<String>('transactions-$_selectedFilter'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final TransactionDateGroup group in groups) ...<Widget>[
          TransactionDateGroupSection(
            label: group.label,
            children: _buildTransactionGroup(group.transactions),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
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

  List<Widget> _buildTransactionGroup(List<MoneyTransaction> transactions) {
    return <Widget>[
      for (int index = 0; index < transactions.length; index++) ...<Widget>[
        TransactionTile(
          title: transactions[index].title,
          category:
              '${transactions[index].categoryNameSnapshot} - ${_paymentMethodLabel(transactions[index].paymentMethod)}',
          formattedAmount: CurrencyFormatter.formatRupiah(
            transactions[index].amount,
          ),
          isIncome: transactions[index].type == 'income',
          categoryIcon: CategoryIconMapper.fromCategoryName(
            transactions[index].categoryNameSnapshot,
          ),
          formattedDate: DateFormatter.formatShortDate(
            transactions[index].transactionDate,
          ),
          onTap: () => _openEditForm(transactions[index].uuid),
          trailingAction: _TransactionActions(
            signedAmount:
                '${transactions[index].type == 'income' ? '+' : '-'}${CurrencyFormatter.formatRupiah(transactions[index].amount)}',
            amountColor: transactions[index].type == 'income'
                ? AppColors.success
                : AppColors.danger,
            onEdit: () => _openEditForm(transactions[index].uuid),
            onDelete: () => _confirmDelete(transactions[index]),
          ),
          showDivider: index < transactions.length - 1,
        ),
      ],
    ];
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return AddTransactionSheet(
          onAddExpense: () =>
              _openAddTransaction(context, initialType: 'expense'),
          onAddIncome: () =>
              _openAddTransaction(context, initialType: 'income'),
          onVoiceInput: () => _openVoiceInput(context),
        );
      },
    );
  }

  Future<void> _openAddTransaction(
    BuildContext bottomSheetContext, {
    required String initialType,
  }) async {
    Navigator.of(bottomSheetContext).pop();
    await context.push(
      RouteConstants.transaksiBaru,
      extra: AddEditTransactionArguments(initialType: initialType),
    );
  }

  Future<void> _openVoiceInput(BuildContext bottomSheetContext) async {
    Navigator.of(bottomSheetContext).pop();
    await context.push(RouteConstants.transaksiSuara);
  }

  Future<void> _openEditForm(String transactionUuid) async {
    await context.push('${RouteConstants.keuangan}/$transactionUuid/edit');
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

class _TransactionActions extends StatelessWidget {
  const _TransactionActions({
    required this.signedAmount,
    required this.amountColor,
    required this.onEdit,
    required this.onDelete,
  });

  final String signedAmount;
  final Color amountColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
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
              style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
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
    );
  }
}

class _KeuanganViewData {
  const _KeuanganViewData({required this.summary, required this.transactions});

  final MonthlyTransactionSummary summary;
  final List<MoneyTransaction> transactions;
}

const List<FinanceFilterOption> _transactionFilters = <FinanceFilterOption>[
  FinanceFilterOption(value: 'all', label: 'Semua'),
  FinanceFilterOption(value: 'income', label: 'Pemasukan'),
  FinanceFilterOption(value: 'expense', label: 'Pengeluaran'),
];

String _paymentMethodLabel(String value) {
  if (value.trim().isEmpty) {
    return 'Tidak Dicatat';
  }
  return value;
}
