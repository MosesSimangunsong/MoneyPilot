import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/beranda/widgets/home_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tiga action tampil dan callback terpanggil', (
    WidgetTester tester,
  ) async {
    var expenseTapped = false;
    var incomeTapped = false;
    var voiceTapped = false;

    await tester.pumpWidget(
      _TestApp(
        child: HomeQuickActions(
          onAddExpense: () => expenseTapped = true,
          onAddIncome: () => incomeTapped = true,
          onVoiceInput: () => voiceTapped = true,
        ),
      ),
    );

    expect(find.text('Tambah pengeluaran'), findsOneWidget);
    expect(find.text('Tambah pemasukan'), findsOneWidget);
    expect(find.text('Catat dengan suara'), findsOneWidget);

    await tester.tap(find.text('Tambah pengeluaran'));
    await tester.tap(find.text('Tambah pemasukan'));
    await tester.tap(find.text('Catat dengan suara'));
    await tester.pumpAndSettle();

    expect(expenseTapped, isTrue);
    expect(incomeTapped, isTrue);
    expect(voiceTapped, isTrue);
  });

  testWidgets('semantic label tersedia', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const _TestApp(
        child: HomeQuickActions(
          onAddExpense: _noop,
          onAddIncome: _noop,
          onVoiceInput: _noop,
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Tambah pengeluaran')),
      matchesSemantics(label: 'Tambah pengeluaran', isButton: true),
    );
    expect(
      tester.getSemantics(find.text('Tambah pemasukan')),
      matchesSemantics(label: 'Tambah pemasukan', isButton: true),
    );
    expect(
      tester.getSemantics(find.text('Catat dengan suara')),
      matchesSemantics(label: 'Catat dengan suara', isButton: true),
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
