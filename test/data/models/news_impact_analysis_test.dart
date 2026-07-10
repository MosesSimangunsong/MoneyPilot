import 'package:app/data/models/news_impact_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse NewsImpactAnalysis dari JSON', () {
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
      'disclaimer': 'Informasi ini bukan nasihat keuangan.',
    });

    expect(analysis.impactScore, 70);
    expect(analysis.asetTerdampak, contains('IHSG'));
  });
}
