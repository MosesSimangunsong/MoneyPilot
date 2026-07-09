import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/primary_button.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key, required this.sessionController});

  final AppSessionController sessionController;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        LucideIcons.fingerprint,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Verifikasi sidik jari',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gunakan fingerprint perangkatmu untuk membuka MoneyPilot.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: widget.sessionController.isAuthenticating
                          ? 'Sedang memverifikasi...'
                          : 'Gunakan Fingerprint',
                      onPressed: widget.sessionController.isAuthenticating
                          ? null
                          : _handleUnlock,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUnlock() async {
    final bool success = await widget.sessionController.unlock();
    if (!mounted || success) {
      return;
    }

    setState(() {
      _errorMessage =
          'Autentikasi gagal. Coba gunakan fingerprint lagi atau buka kunci perangkatmu sesuai pengaturan HP.';
    });
  }
}
