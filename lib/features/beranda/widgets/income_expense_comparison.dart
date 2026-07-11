import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_metric_tile.dart';

class IncomeExpenseComparison extends StatelessWidget {
  const IncomeExpenseComparison({
    super.key,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final double incomeTotal;
  final double expenseTotal;

  @override
  Widget build(BuildContext context) {
    final double maxValue = <double>[incomeTotal, expenseTotal].fold<double>(
      0,
      (double previous, double value) => value > previous ? value : previous,
    );
    final double incomeFactor = maxValue == 0 ? 0 : incomeTotal / maxValue;
    final double expenseFactor = maxValue == 0 ? 0 : expenseTotal / maxValue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Pemasukan dan pengeluaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stacked = constraints.maxWidth < 360;
              final Widget incomeMetric = stacked
                  ? AppMetricTile(
                      label: 'Pemasukan',
                      value: CurrencyFormatter.formatRupiah(incomeTotal),
                      valueColor: AppColors.success,
                    )
                  : Expanded(
                      child: AppMetricTile(
                        label: 'Pemasukan',
                        value: CurrencyFormatter.formatRupiah(incomeTotal),
                        valueColor: AppColors.success,
                      ),
                    );
              final Widget expenseMetric = stacked
                  ? AppMetricTile(
                      label: 'Pengeluaran',
                      value: CurrencyFormatter.formatRupiah(expenseTotal),
                      valueColor: AppColors.danger,
                    )
                  : Expanded(
                      child: AppMetricTile(
                        label: 'Pengeluaran',
                        value: CurrencyFormatter.formatRupiah(expenseTotal),
                        valueColor: AppColors.danger,
                      ),
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            incomeMetric,
                            const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.lg),
                  _ComparisonBar(
                    label: 'Pemasukan',
                    color: AppColors.success,
                    factor: incomeFactor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ComparisonBar(
                    label: 'Pengeluaran',
                    color: AppColors.danger,
                    factor: expenseFactor,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.color,
    required this.factor,
  });

  final String label;
  final Color color;
  final double factor;

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
        ClipRRect(
          borderRadius: AppRadius.pillShape,
          child: LinearProgressIndicator(
            minHeight: 10,
            value: factor.clamp(0, 1),
            backgroundColor: AppColors.surfaceAlt,
            color: color,
          ),
        ),
      ],
    );
  }
}
