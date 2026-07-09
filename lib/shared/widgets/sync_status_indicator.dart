import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.pendingCount = 0,
  });

  final String status;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final _SyncAppearance appearance = _appearanceForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appearance.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: appearance.borderColor),
      ),
      child: Text(
        appearance.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: appearance.textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _SyncAppearance _appearanceForStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'success':
      case 'synced':
        return const _SyncAppearance(
          label: 'Tersinkron',
          backgroundColor: Color(0xFFE9F8EF),
          borderColor: Color(0xFFB7E4C7),
          textColor: AppColors.success,
        );
      case 'failed':
        return const _SyncAppearance(
          label: 'Gagal',
          backgroundColor: Color(0xFFFDECEC),
          borderColor: Color(0xFFF7C7C7),
          textColor: AppColors.danger,
        );
      case 'pending':
        final String label = pendingCount > 0
            ? 'Menunggu $pendingCount'
            : 'Menunggu';
        return _SyncAppearance(
          label: label,
          backgroundColor: const Color(0xFFFFF7E7),
          borderColor: const Color(0xFFF5D48D),
          textColor: AppColors.warning,
        );
      default:
        return const _SyncAppearance(
          label: 'Belum sync',
          backgroundColor: Color(0xFFF4F5F7),
          borderColor: AppColors.border,
          textColor: AppColors.textSecondary,
        );
    }
  }
}

class _SyncAppearance {
  const _SyncAppearance({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}
