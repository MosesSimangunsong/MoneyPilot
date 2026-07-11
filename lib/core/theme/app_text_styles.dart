import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle heroAmount(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.displaySmall!.copyWith(
      color: color ?? AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      letterSpacing: -0.4,
    );
  }

  static TextStyle moneyAmountPositive(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: AppColors.success,
      fontWeight: FontWeight.w700,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  static TextStyle moneyAmountNegative(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: AppColors.danger,
      fontWeight: FontWeight.w700,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  static TextStyle sectionEyebrow(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      color: AppColors.secondaryTeal,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }

  static TextStyle metadata(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle buttonSupplement(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
  }
}
