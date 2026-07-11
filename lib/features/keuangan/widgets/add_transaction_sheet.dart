import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_icon_container.dart';
import '../../../shared/widgets/app_list_tile.dart';

class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({
    super.key,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onVoiceInput,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onVoiceInput;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Catat transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pilih cara pencatatan yang paling nyaman untukmu.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppListTile(
              title: 'Catat pengeluaran',
              subtitle: 'Buka form manual dengan fokus pengeluaran.',
              leading: const AppIconContainer(
                icon: LucideIcons.arrowUpRight,
                foregroundColor: AppColors.danger,
                backgroundColor: AppColors.dangerSoft,
              ),
              trailing: const Icon(Icons.chevron_right),
              semanticLabel: 'Catat pengeluaran',
              onTap: onAddExpense,
            ),
            AppListTile(
              title: 'Catat pemasukan',
              subtitle: 'Buka form manual dengan fokus pemasukan.',
              leading: const AppIconContainer(
                icon: LucideIcons.arrowDownLeft,
                foregroundColor: AppColors.success,
                backgroundColor: AppColors.successSoft,
              ),
              trailing: const Icon(Icons.chevron_right),
              semanticLabel: 'Catat pemasukan',
              onTap: onAddIncome,
            ),
            AppListTile(
              title: 'Catat dengan suara',
              subtitle: 'Masuk ke input suara lalu konfirmasi hasil parser.',
              leading: const AppIconContainer(
                icon: LucideIcons.mic,
                foregroundColor: AppColors.primaryBlue,
                backgroundColor: AppColors.primarySoft,
              ),
              trailing: const Icon(Icons.chevron_right),
              semanticLabel: 'Catat dengan suara',
              onTap: onVoiceInput,
            ),
          ],
        ),
      ),
    );
  }
}
