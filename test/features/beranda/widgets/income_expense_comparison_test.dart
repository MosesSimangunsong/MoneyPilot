import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/beranda/widgets/income_expense_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kedua label tampil', (WidgetTester tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: IncomeExpenseComparison(
          incomeTotal: 1000000,
          expenseTotal: 250000,
        ),
      ),
    );

    expect(find.text('Pemasukan dan pengeluaran'), findsOneWidget);
    expect(find.text('Pemasukan'), findsNWidgets(2));
    expect(find.text('Pengeluaran'), findsNWidgets(2));
  });

  testWidgets('nilai nol aman', (WidgetTester tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: IncomeExpenseComparison(incomeTotal: 0, expenseTotal: 0),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('perbandingan tidak membagi dengan nol', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: IncomeExpenseComparison(incomeTotal: 0, expenseTotal: 0),
      ),
    );

    final List<LinearProgressIndicator> indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(
      indicators.every((LinearProgressIndicator item) => item.value == 0),
      isTrue,
    );
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
