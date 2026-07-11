import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/route_constants.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/category_icon_mapper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/money_transaction.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/app_loading_state.dart';
import '../../shared/widgets/app_section_header.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../keuangan/add_edit_transaction_screen.dart';
import 'widgets/home_cashflow_card.dart';
import 'widgets/home_insight_card.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/income_expense_comparison.dart';

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
          builder: (BuildContext context, AsyncSnapshot<void> streamSnapshot) {
            return FutureBuilder<_BerandaViewData>(
              future: _loadViewData(),
              builder: (BuildContext context, AsyncSnapshot<_BerandaViewData> snapshot) {
                final _BerandaViewData? data = snapshot.data;
                return AppPage(
                  title: 'Halo, ${sessionController.userName}',
                  header: AppSectionHeader(
                    title: 'Halo, ${sessionController.userName}',
                    subtitle: 'Ini kondisi keuanganmu bulan ini.',
                  ),
                  actions: <Widget>[
                    IconButton(
                      tooltip: 'Pengaturan',
                      onPressed: () => context.push(RouteConstants.settings),
                      icon: const Icon(LucideIcons.settings2),
                    ),
                  ],
                  children: <Widget>[
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        data == null)
                      const AppLoadingState(message: 'Memuat ringkasan beranda')
                    else if (snapshot.hasError)
                      const AppErrorState(
                        title: 'Ringkasan belum bisa dimuat',
                        description:
                            'Coba buka lagi beberapa saat lagi. Data lokal aplikasi mungkin masih disiapkan.',
                      )
                    else if (data != null) ...<Widget>[
                      HomeCashflowCard(summary: data.summary),
                      const SizedBox(height: AppSpacing.xl),
                      HomeQuickActions(
                        onAddExpense: () => _openAddTransaction(
                          context,
                          initialType: 'expense',
                        ),
                        onAddIncome: () =>
                            _openAddTransaction(context, initialType: 'income'),
                        onVoiceInput: () =>
                            context.push(RouteConstants.transaksiSuara),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      IncomeExpenseComparison(
                        incomeTotal: data.summary.incomeTotal,
                        expenseTotal: data.summary.expenseTotal,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      HomeInsightCard(
                        incomeTotal: data.summary.incomeTotal,
                        expenseTotal: data.summary.expenseTotal,
                        cashflow: data.summary.cashflow,
                        transactionCount: data.summary.transactionCount,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppSectionHeader(
                        title: 'Transaksi terbaru',
                        action: TextButton(
                          onPressed: () => context.go(RouteConstants.keuangan),
                          child: const Text('Lihat semua'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (data.summary.isEmpty)
                        const AppEmptyState(
                          icon: LucideIcons.wallet,
                          title: 'Belum ada transaksi bulan ini',
                          description:
                              'Mulai catat transaksi untuk melihat arus kas, insight, dan riwayat terbaru di beranda.',
                        )
                      else
                        ..._buildRecentTransactions(
                          data.summary.recentTransactions,
                        ),
                    ] else if (streamSnapshot.hasError)
                      const AppErrorState(
                        title: 'Beranda belum siap ditampilkan',
                        description:
                            'Data transaksi belum bisa dibaca saat ini. Coba buka lagi beberapa saat lagi.',
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

  Future<void> _openAddTransaction(
    BuildContext context, {
    required String initialType,
  }) async {
    await context.push(
      RouteConstants.transaksiBaru,
      extra: AddEditTransactionArguments(initialType: initialType),
    );
  }

  List<Widget> _buildRecentTransactions(List<MoneyTransaction> transactions) {
    return <Widget>[
      for (int index = 0; index < transactions.length; index++) ...<Widget>[
        TransactionTile(
          title: transactions[index].title,
          category: transactions[index].categoryNameSnapshot,
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
          showDivider: index < transactions.length - 1,
        ),
      ],
    ];
  }
}

class _BerandaViewData {
  const _BerandaViewData({required this.summary});

  final MonthlyTransactionSummary summary;
}
