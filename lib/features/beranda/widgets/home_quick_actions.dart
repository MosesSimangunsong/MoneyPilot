import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_icon_container.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileWidth = constraints.maxWidth < 360
            ? constraints.maxWidth
            : (constraints.maxWidth - (AppSpacing.md * 2)) / 3;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            _QuickActionTile(
              width: tileWidth,
              icon: LucideIcons.arrowUpRight,
              label: 'Tambah pengeluaran',
              semanticLabel: 'Tambah pengeluaran',
              foregroundColor: AppColors.danger,
              backgroundColor: AppColors.dangerSoft,
              onTap: onAddExpense,
            ),
            _QuickActionTile(
              width: tileWidth,
              icon: LucideIcons.arrowDownLeft,
              label: 'Tambah pemasukan',
              semanticLabel: 'Tambah pemasukan',
              foregroundColor: AppColors.success,
              backgroundColor: AppColors.successSoft,
              onTap: onAddIncome,
            ),
            _QuickActionTile(
              width: tileWidth,
              icon: LucideIcons.mic,
              label: 'Catat dengan suara',
              semanticLabel: 'Catat dengan suara',
              foregroundColor: AppColors.primaryBlue,
              backgroundColor: AppColors.primarySoft,
              onTap: onVoiceInput,
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.card,
              onTap: onTap,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppIconContainer(
                      icon: icon,
                      foregroundColor: foregroundColor,
                      backgroundColor: backgroundColor,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
