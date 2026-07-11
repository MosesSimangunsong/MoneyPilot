import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/keuangan/widgets/add_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tiga opsi tampil dan callback masing-masing terpanggil', (
    WidgetTester tester,
  ) async {
    var expenseTapped = false;
    var incomeTapped = false;
    var voiceTapped = false;

    await tester.pumpWidget(
      _TestApp(
        child: AddTransactionSheet(
          onAddExpense: () => expenseTapped = true,
          onAddIncome: () => incomeTapped = true,
          onVoiceInput: () => voiceTapped = true,
        ),
      ),
    );

    expect(find.text('Catat pengeluaran'), findsOneWidget);
    expect(find.text('Catat pemasukan'), findsOneWidget);
    expect(find.text('Catat dengan suara'), findsOneWidget);

    await tester.tap(find.text('Catat pengeluaran'));
    await tester.tap(find.text('Catat pemasukan'));
    await tester.tap(find.text('Catat dengan suara'));
    await tester.pumpAndSettle();

    expect(expenseTapped, isTrue);
    expect(incomeTapped, isTrue);
    expect(voiceTapped, isTrue);
  });

  testWidgets('safe area dan semantics tersedia', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const _TestApp(
        child: AddTransactionSheet(
          onAddExpense: _noop,
          onAddIncome: _noop,
          onVoiceInput: _noop,
        ),
      ),
    );

    expect(find.byType(SafeArea), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Catat pengeluaran')).label,
      contains('Catat pengeluaran'),
    );
    expect(
      tester.getSemantics(find.text('Catat pemasukan')).label,
      contains('Catat pemasukan'),
    );
    expect(
      tester.getSemantics(find.text('Catat dengan suara')).label,
      contains('Catat dengan suara'),
    );

    semantics.dispose();
  });
}

void _noop() {}

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
