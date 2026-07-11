import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_metric_tile.dart';

class FinanceMonthlySummary extends StatelessWidget {
  const FinanceMonthlySummary({super.key, required this.summary});

  final MonthlyTransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ringkasan ${DateFormatter.formatMonthYear(summary.month)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pantau arus kas aktifmu tanpa mengubah cara perhitungannya.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: <Widget>[
              SizedBox(
                width: 140,
                child: AppMetricTile(
                  label: 'Pemasukan',
                  value: CurrencyFormatter.formatRupiah(summary.incomeTotal),
                  valueColor: AppColors.success,
                ),
              ),
              SizedBox(
                width: 140,
                child: AppMetricTile(
                  label: 'Pengeluaran',
                  value: CurrencyFormatter.formatRupiah(summary.expenseTotal),
                  valueColor: AppColors.danger,
                ),
              ),
              SizedBox(
                width: 140,
                child: AppMetricTile(
                  label: 'Cashflow',
                  value: CurrencyFormatter.formatRupiah(summary.cashflow),
                  valueColor: summary.cashflow >= 0
                      ? AppColors.primaryDark
                      : AppColors.danger,
                ),
              ),
              SizedBox(
                width: 140,
                child: AppMetricTile(
                  label: 'Jumlah transaksi',
                  value: '${summary.transactionCount}',
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
