import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/app_metric_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('label, value, dan supporting text tampil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AppMetricTile(
          label: 'Pemasukan',
          value: 'Rp 100.000',
          supportingText: 'Bulan ini',
          icon: LucideIcons.arrowDownLeft,
        ),
      ),
    );

    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsOneWidget);
    expect(find.text('Bulan ini'), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowDownLeft), findsOneWidget);
  });

  testWidgets(
    'custom value color bekerja dan value panjang tidak melempar exception',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(220, 240));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _TestApp(
          child: const SizedBox(
            width: 120,
            child: AppMetricTile(
              label: 'Cashflow',
              value: 'Rp 123.456.789.012.345,67',
              valueColor: AppColors.success,
            ),
          ),
        ),
      );

      final Text valueText = tester.widget<Text>(
        find.text('Rp 123.456.789.012.345,67'),
      );
      expect(valueText.style?.color, AppColors.success);
      expect(tester.takeException(), isNull);
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }
}
