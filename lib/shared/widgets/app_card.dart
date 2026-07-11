import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

enum AppCardShadowLevel { none, subtle, raised, overlay }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.showBorder = true,
    this.backgroundColor,
    this.shadowLevel = AppCardShadowLevel.none,
    this.semanticLabel,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? backgroundColor;
  final AppCardShadowLevel shadowLevel;
  final String? semanticLabel;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: radius ?? AppRadius.card,
        border: showBorder ? Border.all(color: AppColors.border) : null,
        boxShadow: _boxShadowForLevel(shadowLevel),
      ),
      child: Padding(padding: padding, child: child),
    );

    final Widget semanticChild = semanticLabel == null
        ? content
        : Semantics(container: true, label: semanticLabel, child: content);

    if (onTap == null) {
      return semanticChild;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius ?? AppRadius.card,
        onTap: onTap,
        child: semanticChild,
      ),
    );
  }

  List<BoxShadow>? _boxShadowForLevel(AppCardShadowLevel level) {
    switch (level) {
      case AppCardShadowLevel.none:
        return null;
      case AppCardShadowLevel.subtle:
        return AppShadows.subtle;
      case AppCardShadowLevel.raised:
        return AppShadows.raised;
      case AppCardShadowLevel.overlay:
        return AppShadows.overlay;
    }
  }
}
