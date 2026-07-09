import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class PortofolioScreen extends StatelessWidget {
  const PortofolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Portofolio',
      description: 'Pantau posisi investasimu dengan tampilan yang tenang.',
      children: <Widget>[
        InfoCard(
          title: 'Portofolio saham manual akan dibangun bertahap',
          description:
              'Tahap 1 menyiapkan shell, theme, dan ruang layar yang nanti diisi transaksi saham, dividen, serta ringkasan P/L.',
        ),
        SizedBox(height: AppSpacing.lg),
        InfoCard(
          title: 'Prinsip yang sudah dikunci',
          description:
              'Metode moving average, input manual, update harga via backend, dan fallback harga terakhir/manual sementara.',
        ),
      ],
    );
  }
}
