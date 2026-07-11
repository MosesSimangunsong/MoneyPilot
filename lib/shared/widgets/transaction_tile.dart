import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_icon_container.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.formattedAmount,
    required this.isIncome,
    required this.formattedDate,
    this.categoryIcon,
    this.onTap,
    this.trailingAction,
    this.showDivider = false,
  });

  final String title;
  final String category;
  final String formattedAmount;
  final bool isIncome;
  final String formattedDate;
  final IconData? categoryIcon;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Color amountColor = isIncome ? AppColors.success : AppColors.danger;
    final String signedAmount =
        '${isIncome ? '+' : '-'}${_normalizeAmount(formattedAmount)}';
    final String semanticsLabel =
        '$title, transaksi ${isIncome ? 'pemasukan' : 'pengeluaran'}, $signedAmount, kategori $category, tanggal $formattedDate';

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconContainer(
            icon:
                categoryIcon ??
                (isIncome
                    ? LucideIcons.arrowDownLeft
                    : LucideIcons.arrowUpRight),
            foregroundColor: amountColor,
            backgroundColor: isIncome
                ? AppColors.successSoft
                : AppColors.dangerSoft,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$category - $formattedDate',
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child:
                trailingAction ??
                Text(
                  signedAmount,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ],
      ),
    );

    final Widget tile = Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );

    if (!showDivider) {
      return tile;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[tile, const Divider(height: 1)],
    );
  }

  String _normalizeAmount(String value) {
    final String trimmed = value.trim();
    if (trimmed.startsWith('+') || trimmed.startsWith('-')) {
      return trimmed.substring(1).trimLeft();
    }
    return trimmed;
  }
}
