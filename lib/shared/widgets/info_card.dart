import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_card.dart';

enum InfoCardVariant { neutral, information, success, warning, danger }

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    this.trailing,
    this.variant = InfoCardVariant.neutral,
  });

  final String title;
  final String description;
  final Widget? trailing;
  final InfoCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _InfoCardAppearance appearance = _appearanceForVariant(variant);

    return AppCard(
      backgroundColor: appearance.backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(appearance.icon, color: appearance.iconColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }

  _InfoCardAppearance _appearanceForVariant(InfoCardVariant value) {
    switch (value) {
      case InfoCardVariant.neutral:
        return const _InfoCardAppearance(
          backgroundColor: AppColors.surface,
          iconColor: AppColors.primaryNavy,
          icon: LucideIcons.info,
        );
      case InfoCardVariant.information:
        return const _InfoCardAppearance(
          backgroundColor: AppColors.infoSoft,
          iconColor: AppColors.info,
          icon: LucideIcons.sparkles,
        );
      case InfoCardVariant.success:
        return const _InfoCardAppearance(
          backgroundColor: AppColors.successSoft,
          iconColor: AppColors.success,
          icon: LucideIcons.badgeCheck,
        );
      case InfoCardVariant.warning:
        return const _InfoCardAppearance(
          backgroundColor: AppColors.warningSoft,
          iconColor: AppColors.warning,
          icon: LucideIcons.alertTriangle,
        );
      case InfoCardVariant.danger:
        return const _InfoCardAppearance(
          backgroundColor: AppColors.dangerSoft,
          iconColor: AppColors.danger,
          icon: LucideIcons.shieldAlert,
        );
    }
  }
}

class _InfoCardAppearance {
  const _InfoCardAppearance({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
}
