import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/keuangan/widgets/finance_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pilihan tampil dan selected state benar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: FinanceFilterBar(
          options: const <FinanceFilterOption>[
            FinanceFilterOption(value: 'all', label: 'Semua'),
            FinanceFilterOption(value: 'income', label: 'Pemasukan'),
            FinanceFilterOption(value: 'expense', label: 'Pengeluaran'),
          ],
          selectedValue: 'income',
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);

    final ChoiceChip incomeChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Pemasukan'),
    );
    expect(incomeChip.selected, isTrue);
  });

  testWidgets('callback terpanggil', (WidgetTester tester) async {
    String? selected;

    await tester.pumpWidget(
      _TestApp(
        child: FinanceFilterBar(
          options: const <FinanceFilterOption>[
            FinanceFilterOption(value: 'all', label: 'Semua'),
            FinanceFilterOption(value: 'income', label: 'Pemasukan'),
          ],
          selectedValue: 'all',
          onSelected: (String value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();

    expect(selected, 'income');
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }
}
