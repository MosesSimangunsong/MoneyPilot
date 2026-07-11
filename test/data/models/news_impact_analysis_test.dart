import 'package:app/data/models/news_impact_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse NewsImpactAnalysis dari JSON dengan metadata baru', () {
    final analysis = NewsImpactAnalysis.fromJson(<String, dynamic>{
      'newsId': 'news-1',
      'judul': 'Judul berita',
      'ringkasan': 'Ringkasan',
      'kategori': 'Geopolitik',
      'asetTerdampak': <String>['IHSG', 'USD/IDR'],
      'impactScore': 70,
      'confidenceScore': 55,
      'dampakPotensial': 'Berpotensi memengaruhi sentimen.',
      'rantaiSebabAkibat': <String>['Langkah 1', 'Langkah 2'],
      'dataPendukung': <String>['Data 1'],
      'skenarioPositif': 'Skenario positif',
      'skenarioNegatif': 'Skenario negatif',
      'halYangPerluDipantau': <String>['Pantau 1'],
      'kesimpulanPemula': 'Kesimpulan',
      'disclaimer':
          'Analisis ini bersifat edukatif dan bukan rekomendasi beli atau jual. Risiko investasi sepenuhnya berada di tangan pengguna.',
      'isAiGenerated': true,
      'isFallback': false,
      'isCached': false,
      'provider': 'openai',
      'model': 'gpt-4.1-mini',
      'fallbackReason': null,
      'generatedAt': '2026-07-10T12:00:00Z',
      'cacheTtlSeconds': 86400,
    });

    expect(analysis.impactScore, 70);
    expect(analysis.asetTerdampak, contains('IHSG'));
    expect(analysis.isAiGenerated, true);
    expect(analysis.isFallback, false);
    expect(analysis.provider, 'openai');
    expect(analysis.cacheTtlSeconds, 86400);
    expect(
      analysis.disclaimer,
      'Analisis ini bersifat edukatif dan bukan rekomendasi beli atau jual. Risiko investasi sepenuhnya berada di tangan pengguna.',
    );
  });
}
