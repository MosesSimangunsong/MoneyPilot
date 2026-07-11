import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/repositories/transaction_repository.dart';
import 'package:app/features/beranda/widgets/home_cashflow_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cashflow income dan expense tampil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: HomeCashflowCard(
          summary: MonthlyTransactionSummary(
            month: DateTime.utc(2026, 7),
            incomeTotal: 1000000,
            expenseTotal: 250000,
            transactionCount: 2,
            recentTransactions: const <MoneyTransaction>[],
          ),
        ),
      ),
    );

    expect(find.text('Cashflow bulan ini'), findsOneWidget);
    expect(find.text('Rp750.000'), findsOneWidget);
    expect(find.text('Rp1.000.000'), findsOneWidget);
    expect(find.text('Rp250.000'), findsOneWidget);
  });

  testWidgets('nilai negatif tidak crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: HomeCashflowCard(
          summary: MonthlyTransactionSummary(
            month: DateTime.utc(2026, 7),
            incomeTotal: 50000,
            expenseTotal: 125000,
            transactionCount: 2,
            recentTransactions: const <MoneyTransaction>[],
          ),
        ),
      ),
    );

    expect(find.text('-Rp75.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nilai panjang tetap aman dirender', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _TestApp(
        child: HomeCashflowCard(
          summary: MonthlyTransactionSummary(
            month: DateTime.utc(2026, 7),
            incomeTotal: 9999999999,
            expenseTotal: 1234567890,
            transactionCount: 5,
            recentTransactions: const <MoneyTransaction>[],
          ),
        ),
      ),
    );

    expect(find.text('Rp8.765.432.109'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
