import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.supportingText,
    this.icon,
    this.valueColor,
    this.emphasize = false,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final String? supportingText;
  final IconData? icon;
  final Color? valueColor;
  final bool emphasize;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ExcludeSemantics(
                child: Icon(icon, size: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: (emphasize ? textTheme.titleLarge : textTheme.titleMedium)
              ?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (supportingText?.trim().isNotEmpty == true) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            supportingText!,
            softWrap: true,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
