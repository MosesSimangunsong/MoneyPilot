import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'app_status_badge.dart';

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
    return AppStatusBadge(
      label: appearance.label,
      variant: appearance.variant,
      icon: appearance.icon,
      compact: true,
    );
  }

  _SyncAppearance _appearanceForStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'success':
      case 'synced':
        return const _SyncAppearance(
          label: 'Tersinkron',
          variant: AppStatusBadgeVariant.success,
          icon: LucideIcons.checkCircle2,
        );
      case 'failed':
        return const _SyncAppearance(
          label: 'Gagal sync',
          variant: AppStatusBadgeVariant.danger,
          icon: LucideIcons.alertTriangle,
        );
      case 'pending':
        final String label = pendingCount > 0
            ? 'Menunggu sync ($pendingCount)'
            : 'Menunggu sync';
        return _SyncAppearance(
          label: label,
          variant: AppStatusBadgeVariant.warning,
          icon: LucideIcons.clock3,
        );
      default:
        return const _SyncAppearance(
          label: 'Belum disinkronkan',
          variant: AppStatusBadgeVariant.neutral,
          icon: LucideIcons.cloudOff,
        );
    }
  }
}

class _SyncAppearance {
  const _SyncAppearance({
    required this.label,
    required this.variant,
    required this.icon,
  });

  final String label;
  final AppStatusBadgeVariant variant;
  final IconData icon;
}
