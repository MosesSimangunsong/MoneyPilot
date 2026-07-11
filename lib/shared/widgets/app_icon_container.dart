import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppIconContainer extends StatelessWidget {
  const AppIconContainer({
    super.key,
    required this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 22,
    this.semanticLabel,
    this.borderRadius,
  });

  final IconData icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = Icon(
      icon,
      size: iconSize,
      color: foregroundColor ?? AppColors.primaryNavy,
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        excluding: semanticLabel == null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.primarySoft,
            borderRadius: borderRadius ?? AppRadius.card,
          ),
          alignment: Alignment.center,
          child: iconWidget,
        ),
      ),
    );
  }
}
