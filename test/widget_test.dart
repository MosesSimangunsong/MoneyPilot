import 'package:app/core/session/app_session_controller.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/services/biometric_service.dart';
import 'package:app/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menampilkan onboarding dengan copy fitur aktual', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppSessionController sessionController = AppSessionController(
      biometricService: _FakeBiometricService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(sessionController: sessionController),
      ),
    );

    expect(find.text('Selamat datang di MoneyPilot'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Moses');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Catat transaksi dengan suara Indonesia'), findsOneWidget);
    expect(find.textContaining('voice input Bahasa Indonesia'), findsNothing);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Penyimpanan lokal tetap jadi fondasi utama'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'portofolio, dividen, watchlist, berita, dan analisis edukatif',
      ),
      findsOneWidget,
    );
  });
}

class _FakeBiometricService extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate() async => false;
}
