import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_card.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticLabel: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 32, color: AppColors.secondaryTeal),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (primaryActionLabel != null &&
              onPrimaryAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: primaryActionLabel!,
              onPressed: onPrimaryAction,
            ),
          ],
          if (secondaryActionLabel != null &&
              onSecondaryAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
            ),
          ],
        ],
      ),
    );
  }
}
