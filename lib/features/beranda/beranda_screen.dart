import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/category_repository.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({
    super.key,
    required this.sessionController,
    required this.categoryRepository,
  });

  final AppSessionController sessionController;
  final CategoryRepository categoryRepository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionController,
      builder: (BuildContext context, Widget? child) {
        return AppPage(
          title: 'Halo, ${sessionController.userName}',
          description:
              'Ringkasan keuangan dan investasimu akan tampil di sini setelah modul data inti dibangun.',
          actions: <Widget>[
            IconButton(
              tooltip: 'Info keamanan',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sessionController.biometricSupported
                          ? 'Biometric ${sessionController.biometricEnabled ? 'aktif' : 'nonaktif'} untuk tahap fondasi ini.'
                          : 'Perangkat ini belum mendukung biometric.',
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.shield),
            ),
          ],
          children: <Widget>[
            const InfoCard(
              title: 'Ringkasan bulan ini',
              description:
                  'Tahap berikutnya akan mengisi area ini dengan cashflow, transaksi terbaru, dan status sinkronisasi.',
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<int>(
              future: categoryRepository.countActiveCategories(),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                final int totalKategori = snapshot.data ?? 0;
                return InfoCard(
                  title: 'Fondasi data lokal siap',
                  description: totalKategori == 0
                      ? 'Database lokal sedang menyiapkan kategori bawaan MoneyPilot.'
                      : '$totalKategori kategori bawaan sudah tersedia dari seed awal Isar.',
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              title: 'Portofolio',
              description:
                  'Nilai portofolio, P/L, dan berita penting akan muncul di sini setelah modul keuangan dan saham selesai.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tahap 1 sudah menyiapkan navigasi utama, onboarding ringkas, dan lapisan keamanan awal.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
              ),
            ),
          ],
        );
      },
    );
  }
}
