import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_spacing.dart';

class FinanceFilterOption {
  const FinanceFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class FinanceFilterBar extends StatelessWidget {
  const FinanceFilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<FinanceFilterOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      child: Wrap(
        key: ValueKey<String>(selectedValue),
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options
            .map(
              (FinanceFilterOption option) => ChoiceChip(
                label: Text(option.label),
                selected: selectedValue == option.value,
                avatar: selectedValue == option.value
                    ? const Icon(Icons.check, size: 18)
                    : null,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selectedValue == option.value
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
                onSelected: (bool isSelected) {
                  if (isSelected) {
                    onSelected(option.value);
                  }
                },
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
