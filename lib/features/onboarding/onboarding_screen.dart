import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.sessionController,
  });

  final AppSessionController sessionController;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _currentStep = 0;
  bool _enableBiometric = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.sessionController.userName == 'Teman'
        ? ''
        : widget.sessionController.userName;
    _enableBiometric = widget.sessionController.biometricSupported;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Selamat datang di MoneyPilot', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Kita siapkan alur awal yang ringkas supaya kamu bisa cepat masuk ke aplikasi.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ProgressHeader(currentStep: _currentStep),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: _buildStepContent(context)),
              const SizedBox(height: AppSpacing.lg),
              if (_currentStep > 0)
                SecondaryButton(
                  label: 'Kembali',
                  onPressed: () {
                    setState(() {
                      _currentStep -= 1;
                    });
                  },
                ),
              if (_currentStep > 0) const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: _currentStep == 3 ? 'Masuk Beranda' : 'Lanjutkan',
                onPressed: _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(context);
      case 1:
        return _buildBiometricStep(context);
      case 2:
        return _buildMicrophoneStep(context);
      case 3:
        return _buildSpreadsheetStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const InfoCard(
          title: 'Mulai dengan nama panggilan',
          description:
              'Nama ini akan dipakai untuk sapaan ringan di Beranda agar aplikasi terasa lebih personal.',
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nama panggilan',
            hintText: 'Contoh: Moses',
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricStep(BuildContext context) {
    final bool isSupported = widget.sessionController.biometricSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoCard(
          title: isSupported
              ? 'Aktifkan keamanan biometric'
              : 'Biometric belum tersedia',
          description: isSupported
              ? 'MoneyPilot bisa meminta fingerprint saat aplikasi dibuka atau saat kamu kembali setelah beberapa menit.'
              : 'Perangkat ini belum mendukung fingerprint atau biometric. Untuk MVP, aplikasi tetap bisa dipakai tanpa PIN internal.',
          trailing: Icon(
            isSupported ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            color: isSupported ? AppColors.primary : AppColors.warning,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SwitchListTile(
          value: isSupported && _enableBiometric,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: isSupported
              ? (bool value) {
                  setState(() {
                    _enableBiometric = value;
                  });
                }
              : null,
          title: const Text('Gunakan fingerprint saat aplikasi dibuka'),
          subtitle: Text(
            isSupported
                ? 'MoneyPilot akan meminta verifikasi lagi jika aplikasi ditinggal 3 menit atau lebih.'
                : 'Pengaturan ini bisa kamu cek lagi nanti jika perangkat berubah.',
          ),
        ),
      ],
    );
  }

  Widget _buildMicrophoneStep(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoCard(
          title: 'Siapkan akses mikrofon',
          description:
              'Tahap voice input akan dibangun setelah fondasi aplikasi siap. Saat fitur itu dibuka nanti, sistem akan meminta izin mikrofon perangkatmu.',
        ),
        SizedBox(height: AppSpacing.xl),
        InfoCard(
          title: 'Kenapa belum diminta sekarang?',
          description:
              'Tahap 1 fokus pada fondasi aplikasi. Kita tetap menempatkan langkah ini di onboarding supaya alur produk sudah sesuai dokumen.',
        ),
      ],
    );
  }

  Widget _buildSpreadsheetStep(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoCard(
          title: 'Setup spreadsheet bersifat opsional',
          description:
              'Kamu tetap bisa memakai MoneyPilot secara lokal dulu. URL Google Apps Script dan secret token akan diatur dari halaman Pengaturan pada tahap berikutnya.',
        ),
        SizedBox(height: AppSpacing.xl),
        InfoCard(
          title: 'Yang akan kamu dapat setelah masuk',
          description:
              'Beranda, Berita, Keuangan, Portofolio, dan Analisis sudah siap sebagai kerangka navigasi utama untuk MVP.',
        ),
      ],
    );
  }

  Future<void> _handleContinue() async {
    if (_currentStep == 0) {
      final String trimmedName = _nameController.text.trim();
      if (trimmedName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama panggilan perlu diisi terlebih dahulu.'),
          ),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    await widget.sessionController.completeOnboarding(
      userName: _nameController.text.trim(),
      enableBiometric: _enableBiometric,
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(4, (int index) {
        final bool isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : AppSpacing.sm),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
