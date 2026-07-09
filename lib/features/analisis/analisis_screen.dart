import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layouts/app_page.dart';
import '../../shared/widgets/info_card.dart';

class AnalisisScreen extends StatelessWidget {
  const AnalisisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Analisis',
      description:
          'Ruang untuk riset keuangan yang lebih mendalam akan berkembang dari sini.',
      children: <Widget>[
        InfoCard(
          title: 'Fitur analisis lanjutan sedang disiapkan',
          description:
              'Watchlist, catatan analisis pribadi, dan fondasi analisis saham atau forex akan masuk di milestone berikutnya.',
        ),
        SizedBox(height: AppSpacing.lg),
        InfoCard(
          title: 'Bukan rekomendasi trading',
          description:
              'MoneyPilot dirancang untuk edukasi dan pemantauan, bukan memberi sinyal beli atau jual.',
        ),
      ],
    );
  }
}
