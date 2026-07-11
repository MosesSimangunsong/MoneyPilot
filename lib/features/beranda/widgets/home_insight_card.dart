import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/info_card.dart';

class HomeInsightCard extends StatelessWidget {
  const HomeInsightCard({
    super.key,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.cashflow,
    required this.transactionCount,
  });

  final double incomeTotal;
  final double expenseTotal;
  final double cashflow;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final _InsightContent insight = _buildInsight();
    return InfoCard(
      title: 'Insight singkat',
      description: insight.message,
      variant: insight.variant,
      trailing: Icon(insight.icon, color: insight.iconColor, size: 20),
    );
  }

  _InsightContent _buildInsight() {
    if (transactionCount == 0) {
      return const _InsightContent(
        message: 'Mulai catat transaksi pertama untuk melihat insight.',
        variant: InfoCardVariant.information,
        icon: LucideIcons.sparkles,
        iconColor: AppColors.info,
      );
    }

    if (expenseTotal == 0) {
      return const _InsightContent(
        message: 'Belum ada pengeluaran tercatat bulan ini.',
        variant: InfoCardVariant.success,
        icon: LucideIcons.badgeCheck,
        iconColor: AppColors.success,
      );
    }

    if (incomeTotal == 0 && expenseTotal > 0) {
      return const _InsightContent(
        message:
            'Pengeluaran sudah tercatat, tetapi belum ada pemasukan bulan ini.',
        variant: InfoCardVariant.warning,
        icon: LucideIcons.alertTriangle,
        iconColor: AppColors.warning,
      );
    }

    if (cashflow < 0) {
      return const _InsightContent(
        message: 'Pengeluaran bulan ini lebih besar daripada pemasukan.',
        variant: InfoCardVariant.danger,
        icon: LucideIcons.trendingDown,
        iconColor: AppColors.danger,
      );
    }

    return const _InsightContent(
      message: 'Cashflow bulan ini masih positif.',
      variant: InfoCardVariant.success,
      icon: LucideIcons.trendingUp,
      iconColor: AppColors.success,
    );
  }
}

class _InsightContent {
  const _InsightContent({
    required this.message,
    required this.variant,
    required this.icon,
    required this.iconColor,
  });

  final String message;
  final InfoCardVariant variant;
  final IconData icon;
  final Color iconColor;
}
