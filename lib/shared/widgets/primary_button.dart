import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final Widget buttonChild = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label)),
            ],
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label)),
            ],
          );

    final Widget button = Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      value: isLoading ? 'Memuat' : null,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: buttonChild,
        ),
      ),
    );

    return button;
  }
}
