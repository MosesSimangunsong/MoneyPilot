import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/app_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('label dan icon optional tampil', (WidgetTester tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AppStatusBadge(
          label: 'Sinkronisasi aktif',
          icon: LucideIcons.checkCircle2,
        ),
      ),
    );

    expect(find.text('Sinkronisasi aktif'), findsOneWidget);
    expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
  });

  testWidgets('setiap variant dapat dirender tanpa overflow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(260, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: const <Widget>[
            AppStatusBadge(
              label: 'Status netral dengan teks moderat',
              variant: AppStatusBadgeVariant.neutral,
            ),
            AppStatusBadge(
              label: 'Status informasi dengan teks moderat',
              variant: AppStatusBadgeVariant.information,
            ),
            AppStatusBadge(
              label: 'Status sukses dengan teks moderat',
              variant: AppStatusBadgeVariant.success,
            ),
            AppStatusBadge(
              label: 'Status peringatan dengan teks moderat',
              variant: AppStatusBadgeVariant.warning,
            ),
            AppStatusBadge(
              label: 'Status bahaya dengan teks moderat',
              variant: AppStatusBadgeVariant.danger,
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Status'), findsNWidgets(5));
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
