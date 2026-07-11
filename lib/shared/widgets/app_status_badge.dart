import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppStatusBadgeVariant { neutral, information, success, warning, danger }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.variant = AppStatusBadgeVariant.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final AppStatusBadgeVariant variant;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final _BadgeColors colors = _colorsForVariant(variant);
    final double iconSize = compact ? 14 : 16;
    final EdgeInsetsGeometry padding = EdgeInsets.symmetric(
      horizontal: compact ? AppSpacing.sm : AppSpacing.md,
      vertical: compact ? AppSpacing.xs : AppSpacing.sm,
    );

    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: AppRadius.pillShape,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ExcludeSemantics(
                child: Icon(icon, size: iconSize, color: colors.foreground),
              ),
              SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeColors _colorsForVariant(AppStatusBadgeVariant value) {
    switch (value) {
      case AppStatusBadgeVariant.neutral:
        return const _BadgeColors(
          background: AppColors.surfaceAlt,
          border: AppColors.border,
          foreground: AppColors.textSecondary,
        );
      case AppStatusBadgeVariant.information:
        return const _BadgeColors(
          background: AppColors.infoSoft,
          border: AppColors.infoBorder,
          foreground: AppColors.info,
        );
      case AppStatusBadgeVariant.success:
        return const _BadgeColors(
          background: AppColors.successSoft,
          border: AppColors.successBorder,
          foreground: AppColors.success,
        );
      case AppStatusBadgeVariant.warning:
        return const _BadgeColors(
          background: AppColors.warningSoft,
          border: AppColors.warningBorder,
          foreground: AppColors.warning,
        );
      case AppStatusBadgeVariant.danger:
        return const _BadgeColors(
          background: AppColors.dangerSoft,
          border: AppColors.dangerBorder,
          foreground: AppColors.danger,
        );
    }
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
