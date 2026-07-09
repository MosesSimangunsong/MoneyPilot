import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> isAvailable() async {
    final bool canCheckBiometrics =
        await _localAuthentication.canCheckBiometrics;
    final bool isDeviceSupported =
        await _localAuthentication.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Gunakan fingerprint perangkatmu untuk membuka MoneyPilot.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
