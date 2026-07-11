import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('menampilkan detail transaksi pemasukan dengan tanda plus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: TransactionTile(
          title: 'Gaji freelance',
          category: 'Pekerjaan',
          formattedAmount: 'Rp 500.000',
          isIncome: true,
          formattedDate: '11 Jul 2026',
          categoryIcon: LucideIcons.briefcase,
        ),
      ),
    );

    expect(find.text('Gaji freelance'), findsOneWidget);
    expect(find.text('Pekerjaan - 11 Jul 2026'), findsOneWidget);
    expect(find.text('+Rp 500.000'), findsOneWidget);
  });

  testWidgets(
    'menampilkan detail transaksi pengeluaran, callback tap, dan semantics',
    (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _TestApp(
          child: TransactionTile(
            title: 'Makan siang',
            category: 'Makanan',
            formattedAmount: 'Rp 35.000',
            isIncome: false,
            formattedDate: '11 Jul 2026',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('-Rp 35.000'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Makan siang, transaksi pengeluaran, -Rp 35.000, kategori Makanan, tanggal 11 Jul 2026',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Makan siang'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
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
