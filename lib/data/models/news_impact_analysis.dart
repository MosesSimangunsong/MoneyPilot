class NewsImpactAnalysis {
  const NewsImpactAnalysis({
    required this.newsId,
    required this.judul,
    required this.ringkasan,
    required this.kategori,
    required this.asetTerdampak,
    required this.impactScore,
    required this.confidenceScore,
    required this.dampakPotensial,
    required this.rantaiSebabAkibat,
    required this.dataPendukung,
    required this.skenarioPositif,
    required this.skenarioNegatif,
    required this.halYangPerluDipantau,
    required this.kesimpulanPemula,
    required this.disclaimer,
  });

  final String newsId;
  final String judul;
  final String ringkasan;
  final String kategori;
  final List<String> asetTerdampak;
  final int impactScore;
  final int confidenceScore;
  final String dampakPotensial;
  final List<String> rantaiSebabAkibat;
  final List<String> dataPendukung;
  final String skenarioPositif;
  final String skenarioNegatif;
  final List<String> halYangPerluDipantau;
  final String kesimpulanPemula;
  final String disclaimer;

  factory NewsImpactAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      final List<dynamic> values = json[key] as List<dynamic>? ?? <dynamic>[];
      return values
          .map((dynamic item) => item.toString())
          .toList(growable: false);
    }

    int readScore(String key) {
      final dynamic value = json[key];
      if (value is num) {
        return value.round();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return NewsImpactAnalysis(
      newsId: (json['newsId'] as String? ?? '').trim(),
      judul: (json['judul'] as String? ?? '').trim(),
      ringkasan: (json['ringkasan'] as String? ?? '').trim(),
      kategori: (json['kategori'] as String? ?? '').trim(),
      asetTerdampak: readList('asetTerdampak'),
      impactScore: readScore('impactScore'),
      confidenceScore: readScore('confidenceScore'),
      dampakPotensial: (json['dampakPotensial'] as String? ?? '').trim(),
      rantaiSebabAkibat: readList('rantaiSebabAkibat'),
      dataPendukung: readList('dataPendukung'),
      skenarioPositif: (json['skenarioPositif'] as String? ?? '').trim(),
      skenarioNegatif: (json['skenarioNegatif'] as String? ?? '').trim(),
      halYangPerluDipantau: readList('halYangPerluDipantau'),
      kesimpulanPemula: (json['kesimpulanPemula'] as String? ?? '').trim(),
      disclaimer: (json['disclaimer'] as String? ?? '').trim(),
    );
  }
}
