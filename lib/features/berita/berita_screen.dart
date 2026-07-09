import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class BeritaScreen extends StatelessWidget {
  const BeritaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Berita',
      description:
          'Pantau berita yang bisa memengaruhi keuangan dan pasar dari satu tempat.',
      children: <Widget>[
        InfoCard(
          title: 'Feed berita akan hadir di tahap berikutnya',
          description:
              'Tahap ini masih berupa placeholder agar alur navigasi dan struktur layar sudah sesuai dokumen produk.',
        ),
        SizedBox(height: AppSpacing.lg),
        InfoCard(
          title: 'Yang akan dibangun selanjutnya',
          description:
              'Daftar berita, filter kategori, detail berita, bookmark, dan analisis dampak berbasis AI backend.',
        ),
      ],
    );
  }
}
