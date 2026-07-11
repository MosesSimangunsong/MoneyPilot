import 'package:app/core/theme/app_theme.dart';
import 'package:app/shared/widgets/app_icon_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('menampilkan icon dan semantic label bila diberikan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: const AppIconContainer(
          icon: LucideIcons.wallet,
          semanticLabel: 'Ikon dompet',
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
    expect(find.bySemanticsLabel('Ikon dompet'), findsOneWidget);
  });

  testWidgets('custom size bekerja', (WidgetTester tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: const AppIconContainer(
          icon: LucideIcons.wallet,
          size: 60,
          iconSize: 28,
        ),
      ),
    );

    final Size containerSize = tester.getSize(find.byType(Container).first);
    expect(containerSize.width, 60);
    expect(containerSize.height, 60);

    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.wallet));
    expect(icon.size, 28);
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
