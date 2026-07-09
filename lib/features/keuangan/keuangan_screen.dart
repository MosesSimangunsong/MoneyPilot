import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class KeuanganScreen extends StatelessWidget {
  const KeuanganScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Keuangan',
      description: 'Catat pemasukan dan pengeluaranmu dengan cepat.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(LucideIcons.mic),
        label: const Text('Catat Suara'),
      ),
      children: const <Widget>[
        InfoCard(
          title: 'Transaksi manual dan suara belum aktif',
          description:
              'Tahap berikutnya akan membangun daftar transaksi, form tambah transaksi, dan voice confirmation flow.',
        ),
        SizedBox(height: AppSpacing.lg),
        InfoCard(
          title: 'Arah implementasi',
          description:
              'Modul ini akan menjadi rumah untuk cashflow, kategori, laporan sederhana, dan antrean sinkronisasi.',
        ),
      ],
    );
  }
}
