import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasSubtitle = subtitle?.trim().isNotEmpty == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: leading!,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: textTheme.headlineMedium),
              if (hasSubtitle) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          action!,
        ],
      ],
    );
  }
}
