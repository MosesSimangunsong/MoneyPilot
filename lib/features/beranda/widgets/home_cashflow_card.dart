import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_metric_tile.dart';

class HomeCashflowCard extends StatelessWidget {
  const HomeCashflowCard({super.key, required this.summary});

  final MonthlyTransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final Color cashflowColor = summary.cashflow >= 0
        ? Colors.white
        : AppColors.goldSoft;
    final String helperText = summary.transactionCount == 0
        ? 'Mulai catat transaksi pertamamu untuk melihat arus kas bulan ini.'
        : 'Pemasukan dan pengeluaran dirangkum untuk ${DateFormatter.formatMonthYear(summary.month)}.';

    return AppCard(
      radius: AppRadius.heroCard,
      showBorder: false,
      backgroundColor: AppColors.primaryNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Cashflow bulan ini',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.formatRupiah(summary.cashflow),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: cashflowColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            helperText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool useColumn = constraints.maxWidth < 320;
              final Widget incomeMetric = useColumn
                  ? AppMetricTile(
                      label: 'Pemasukan',
                      value: CurrencyFormatter.formatRupiah(
                        summary.incomeTotal,
                      ),
                      valueColor: Colors.white,
                      supportingText: 'Total pemasukan',
                    )
                  : Expanded(
                      child: AppMetricTile(
                        label: 'Pemasukan',
                        value: CurrencyFormatter.formatRupiah(
                          summary.incomeTotal,
                        ),
                        valueColor: Colors.white,
                        supportingText: 'Total pemasukan',
                      ),
                    );
              final Widget expenseMetric = useColumn
                  ? AppMetricTile(
                      label: 'Pengeluaran',
                      value: CurrencyFormatter.formatRupiah(
                        summary.expenseTotal,
                      ),
                      valueColor: Colors.white,
                      supportingText: 'Total pengeluaran',
                    )
                  : Expanded(
                      child: AppMetricTile(
                        label: 'Pengeluaran',
                        value: CurrencyFormatter.formatRupiah(
                          summary.expenseTotal,
                        ),
                        valueColor: Colors.white,
                        supportingText: 'Total pengeluaran',
                      ),
                    );

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: AppRadius.heroCard,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: useColumn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            incomeMetric,
                            const SizedBox(height: AppSpacing.lg),
                            expenseMetric,
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            incomeMetric,
                            const SizedBox(width: AppSpacing.lg),
                            expenseMetric,
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
