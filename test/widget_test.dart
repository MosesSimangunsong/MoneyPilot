import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/session/app_session_controller.dart';
import 'package:app/data/services/biometric_service.dart';
import 'package:app/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('menampilkan onboarding ringkas dengan field nama panggilan',
      (WidgetTester tester) async {
    final AppSessionController sessionController = AppSessionController(
      biometricService: _FakeBiometricService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(sessionController: sessionController),
      ),
    );

    expect(find.text('Selamat datang di MoneyPilot'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}

class _FakeBiometricService extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate() async => false;
}
