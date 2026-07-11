import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('title, subtitle, leading, trailing, dan divider tampil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AppListTile(
          title: 'Kategori',
          subtitle: 'Kelola jenis transaksi',
          leading: Icon(LucideIcons.tag),
          trailing: Icon(Icons.chevron_right),
          showDivider: true,
        ),
      ),
    );

    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Kelola jenis transaksi'), findsOneWidget);
    expect(find.byIcon(LucideIcons.tag), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('callback tap dipanggil', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _TestApp(
        child: AppListTile(title: 'Buka kategori', onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.text('Buka kategori'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
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
