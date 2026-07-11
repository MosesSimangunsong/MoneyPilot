import '../../core/utils/indonesian_number_parser.dart';
import '../models/category.dart';

class TransactionParserService {
  const TransactionParserService();

  VoiceTransactionParseResult parse({
    required String rawText,
    required List<Category> categories,
    DateTime? referenceTime,
  }) {
    final String trimmedRawText = rawText.trim();
    final String normalizedTranscript = normalizeTranscript(trimmedRawText);
    final DateTime now = referenceTime ?? DateTime.now();
    final List<String> warnings = <String>[];
    final List<String> missingFields = <String>[];

    final TransactionTypeDetection typeDetection = detectTransactionType(
      normalizedTranscript,
    );
    final AmountExtraction amountExtraction = extractAmount(
      normalizedTranscript,
    );
    final DateExtraction dateExtraction = extractDate(
      normalizedTranscript,
      referenceTime: now,
    );
    final CategoryDetection categoryDetection = detectCategory(
      normalizedTranscript: normalizedTranscript,
      transactionType: typeDetection.type,
      categories: categories,
    );
    final String description = buildDescription(
      rawTranscript: trimmedRawText,
      normalizedTranscript: normalizedTranscript,
    );

    if (amountExtraction.amount == null) {
      missingFields.add('amount');
      warnings.add('Nominal belum dikenali.');
    }
    if (typeDetection.type == null) {
      missingFields.add('type');
      warnings.add('Tipe transaksi belum yakin. Periksa kembali hasilnya.');
    }
    if (categoryDetection.category == null) {
      missingFields.add('category');
      warnings.add('Kategori belum dikenali. Pilih kategori yang sesuai.');
    }
    if (amountExtraction.isAmbiguous) {
      warnings.add(
        'Terdapat lebih dari satu kandidat nominal. Pastikan nominal yang terisi sudah benar.',
      );
    }
    warnings.addAll(typeDetection.warnings);
    warnings.addAll(dateExtraction.warnings);

    final int confidenceScore = calculateConfidence(
      amountDetected: amountExtraction.amount != null,
      typeDetected: typeDetection.type != null,
      categoryDetected: categoryDetection.category != null,
      dateExplicitlyDetected: dateExtraction.wasExplicitlyDetected,
      description: description,
      penalties: <int>[
        if (amountExtraction.isAmbiguous) 15,
        if (typeDetection.type == null) 20,
      ],
    );

    return VoiceTransactionParseResult(
      originalTranscript: trimmedRawText,
      normalizedTranscript: normalizedTranscript,
      transactionType: typeDetection.type,
      amount: amountExtraction.amount,
      categoryUuid: categoryDetection.category?.uuid,
      categoryName: categoryDetection.category?.name,
      transactionDate: dateExtraction.transactionDate,
      description: description.isEmpty ? trimmedRawText : description,
      confidenceScore: confidenceScore,
      missingFields: missingFields,
      warnings: warnings.toSet().toList(growable: false),
      amountCandidates: amountExtraction.candidates,
      transcriptLooksEmpty: normalizedTranscript.isEmpty,
    );
  }

  String normalizeTranscript(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\brp\b'), ' rupiah ')
        .replaceAll(RegExp(r'\brp(?=\d)'), ' rupiah ')
        .replaceAll(RegExp(r'\bjt\b'), ' juta ')
        .replaceAll(RegExp(r'\brb\b'), ' ribu ')
        .replaceAll(RegExp(r'[^a-z0-9,\.\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  TransactionTypeDetection detectTransactionType(String normalizedTranscript) {
    int incomeScore = 0;
    int expenseScore = 0;
    final List<String> warnings = <String>[];

    for (final String keyword in _incomeKeywords) {
      if (_containsKeyword(normalizedTranscript, keyword)) {
        incomeScore += 3;
      }
    }
    for (final String keyword in _expenseKeywords) {
      if (_containsKeyword(normalizedTranscript, keyword)) {
        expenseScore += 3;
      }
    }
    for (final String keyword in _softIncomeKeywords) {
      if (_containsKeyword(normalizedTranscript, keyword)) {
        incomeScore += 1;
      }
    }
    for (final String keyword in _softExpenseKeywords) {
      if (_containsKeyword(normalizedTranscript, keyword)) {
        expenseScore += 1;
      }
    }

    if (_containsKeyword(normalizedTranscript, 'transfer dari')) {
      incomeScore += 3;
    }
    if (_containsKeyword(normalizedTranscript, 'transfer ke')) {
      expenseScore += 3;
    }

    String? type;
    if (incomeScore > expenseScore) {
      type = 'income';
    } else if (expenseScore > incomeScore) {
      type = 'expense';
    }

    if (incomeScore > 0 && expenseScore > 0) {
      warnings.add(
        'Ucapan mengandung kata yang mirip pemasukan dan pengeluaran.',
      );
    }

    return TransactionTypeDetection(
      type: type,
      incomeScore: incomeScore,
      expenseScore: expenseScore,
      warnings: warnings,
    );
  }

  AmountExtraction extractAmount(String normalizedTranscript) {
    final List<AmountCandidate> candidates = <AmountCandidate>[
      ..._extractScaledNumericCandidates(normalizedTranscript),
      ..._extractWordCandidates(normalizedTranscript),
    ];

    final List<AmountCandidate> deduplicated = <AmountCandidate>[];
    final Set<String> seen = <String>{};
    for (final AmountCandidate candidate in candidates) {
      final String key =
          '${candidate.amount}-${candidate.start}-${candidate.end}';
      if (seen.add(key)) {
        deduplicated.add(candidate);
      }
    }

    if (deduplicated.isEmpty) {
      return const AmountExtraction(
        amount: null,
        candidates: <AmountCandidate>[],
        isAmbiguous: false,
      );
    }

    deduplicated.sort((AmountCandidate a, AmountCandidate b) {
      final int byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      final int byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) {
        return byAmount;
      }
      return a.start.compareTo(b.start);
    });

    return AmountExtraction(
      amount: deduplicated.first.amount.toDouble(),
      candidates: deduplicated,
      isAmbiguous: deduplicated.length > 1,
    );
  }

  CategoryDetection detectCategory({
    required String normalizedTranscript,
    required String? transactionType,
    required List<Category> categories,
  }) {
    if (transactionType == null) {
      return const CategoryDetection(category: null);
    }

    final Map<String, List<String>> keywordMap = transactionType == 'income'
        ? _incomeCategoryKeywords
        : _expenseCategoryKeywords;
    final List<Category> matchingCategories = categories
        .where((Category category) => category.type == transactionType)
        .toList(growable: false);

    for (final MapEntry<String, List<String>> entry in keywordMap.entries) {
      if (!entry.value.any(
        (String keyword) => _containsKeyword(normalizedTranscript, keyword),
      )) {
        continue;
      }

      final Category? matched = _findCategoryByCandidateName(
        matchingCategories,
        entry.key,
      );
      if (matched != null) {
        return CategoryDetection(category: matched);
      }
    }

    return const CategoryDetection(category: null);
  }

  DateExtraction extractDate(
    String normalizedTranscript, {
    required DateTime referenceTime,
  }) {
    final DateTime localNow = referenceTime.toLocal();
    final DateTime today = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      localNow.hour,
      localNow.minute,
      localNow.second,
      localNow.millisecond,
      localNow.microsecond,
    );

    if (_containsKeyword(normalizedTranscript, 'kemarin')) {
      return DateExtraction(
        transactionDate: today.subtract(const Duration(days: 1)).toUtc(),
        wasExplicitlyDetected: true,
        warnings: const <String>[],
      );
    }

    const List<String> sameDayKeywords = <String>[
      'hari ini',
      'tadi',
      'tadi pagi',
      'tadi siang',
      'tadi sore',
      'tadi malam',
      'pagi ini',
      'siang ini',
      'malam ini',
    ];

    if (sameDayKeywords.any(
      (String keyword) => _containsKeyword(normalizedTranscript, keyword),
    )) {
      return DateExtraction(
        transactionDate: today.toUtc(),
        wasExplicitlyDetected: true,
        warnings: const <String>[],
      );
    }

    return DateExtraction(
      transactionDate: today.toUtc(),
      wasExplicitlyDetected: false,
      warnings: const <String>[],
    );
  }

  String buildDescription({
    required String rawTranscript,
    required String normalizedTranscript,
  }) {
    String cleaned = normalizedTranscript;
    for (final String phrase in <String>[
      ..._expenseKeywords,
      ..._incomeKeywords,
      ..._softExpenseKeywords,
      ..._softIncomeKeywords,
      'saya',
      'aku',
      'uang',
      'rupiah',
      'hari ini',
      'kemarin',
      'tadi',
      'tadi pagi',
      'tadi siang',
      'tadi sore',
      'tadi malam',
      'pagi ini',
      'siang ini',
      'malam ini',
      'total',
      'masing masing',
      'masing-masing',
    ]) {
      cleaned = cleaned.replaceAll(
        RegExp('\\b${RegExp.escape(phrase)}\\b'),
        ' ',
      );
    }

    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d[\d.,]*\s*(juta|ribu|rb|k|rupiah)?\b'),
      ' ',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(setengah|nol|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|belas|puluh|ratus|ribu|juta)\b',
      ),
      ' ',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) {
      return rawTranscript.trim();
    }

    return cleaned
        .split(' ')
        .map((String word) {
          if (word.isEmpty) {
            return word;
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  int calculateConfidence({
    required bool amountDetected,
    required bool typeDetected,
    required bool categoryDetected,
    required bool dateExplicitlyDetected,
    required String description,
    List<int> penalties = const <int>[],
  }) {
    int score = 0;
    if (amountDetected) {
      score += 40;
    }
    if (typeDetected) {
      score += 25;
    }
    if (categoryDetected) {
      score += 20;
    }
    if (dateExplicitlyDetected) {
      score += 5;
    }
    if (description.trim().isNotEmpty) {
      score += 10;
    }
    for (final int penalty in penalties) {
      score -= penalty;
    }
    return score.clamp(0, 100);
  }

  List<AmountCandidate> _extractScaledNumericCandidates(String text) {
    final List<AmountCandidate> results = <AmountCandidate>[];
    final RegExp pattern = RegExp(
      r'(?:(total|jumlah)\s+)?(rp\s*)?(\d+(?:[.,]\d+)?)\s*(juta|ribu|rb|k|rupiah)?',
    );

    for (final RegExpMatch match in pattern.allMatches(text)) {
      final String token = match.group(3) ?? '';
      if (token.isEmpty) {
        continue;
      }
      final String suffix = match.group(4) ?? '';
      final double? baseValue = _parseLocaleNumber(token);
      if (baseValue == null || baseValue <= 0) {
        continue;
      }

      int amount = baseValue.round();
      if (suffix == 'juta') {
        amount = (baseValue * 1000000).round();
      } else if (suffix == 'ribu' || suffix == 'rb' || suffix == 'k') {
        amount = (baseValue * 1000).round();
      }

      int priority = suffix.isEmpty ? 10 : 30;
      if ((match.group(1) ?? '').isNotEmpty) {
        priority += 30;
      }
      if ((match.group(2) ?? '').isNotEmpty) {
        priority += 5;
      }

      results.add(
        AmountCandidate(
          amount: amount,
          snippet: match.group(0)!.trim(),
          start: match.start,
          end: match.end,
          priority: priority,
        ),
      );
    }

    return results;
  }

  List<AmountCandidate> _extractWordCandidates(String text) {
    final List<AmountCandidate> results = <AmountCandidate>[];
    final RegExp totalPattern = RegExp(r'(?:total|jumlah)\s+([a-z0-9\s]+)$');
    final RegExpMatch? totalMatch = totalPattern.firstMatch(text);
    if (totalMatch != null) {
      final String totalPhrase = totalMatch.group(1)!.trim();
      final double? totalValue = IndonesianNumberParser.parse(totalPhrase);
      if (totalValue != null && totalValue > 0) {
        results.add(
          AmountCandidate(
            amount: totalValue.round(),
            snippet: totalPhrase,
            start: totalMatch.start,
            end: totalMatch.end,
            priority: 80,
          ),
        );
      }
    }

    final List<String> tokens = text.split(' ');
    if (tokens.isEmpty) {
      return results;
    }

    int? sequenceStart;
    final List<String> sequenceTokens = <String>[];

    void flushSequence(int currentIndex) {
      if (sequenceStart == null || sequenceTokens.isEmpty) {
        sequenceStart = null;
        sequenceTokens.clear();
        return;
      }

      final String phrase = sequenceTokens.join(' ').trim();
      final double? value = IndonesianNumberParser.parse(phrase);
      if (value != null && value > 0) {
        results.add(
          AmountCandidate(
            amount: value.round(),
            snippet: phrase,
            start: sequenceStart!,
            end: currentIndex,
            priority: phrase.contains('juta') || phrase.contains('ribu')
                ? 20
                : 12,
          ),
        );
      }
      sequenceStart = null;
      sequenceTokens.clear();
    }

    for (int index = 0; index < tokens.length; index++) {
      final String token = tokens[index];
      if (_containsNumberWord(token) || double.tryParse(token) != null) {
        sequenceStart ??= index;
        sequenceTokens.add(token);
        continue;
      }
      flushSequence(index);
    }
    flushSequence(tokens.length);

    return results;
  }

  Category? _findCategoryByCandidateName(
    List<Category> categories,
    String candidate,
  ) {
    final String normalizedCandidate = candidate.trim().toLowerCase();
    for (final Category category in categories) {
      final String categoryName = category.name.trim().toLowerCase();
      if (categoryName == normalizedCandidate) {
        return category;
      }
      if (categoryName.contains(normalizedCandidate) ||
          normalizedCandidate.contains(categoryName)) {
        return category;
      }
    }
    return null;
  }

  bool _containsKeyword(String text, String keyword) {
    return RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(text);
  }

  bool _containsNumberWord(String value) {
    return _numberWords.any(
      (String keyword) => _containsKeyword(value, keyword),
    );
  }

  double? _parseLocaleNumber(String value) {
    if (value.contains('.') && value.contains(',')) {
      return double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
    }

    if (value.contains(',')) {
      final List<String> parts = value.split(',');
      final bool looksLikeThousands =
          parts.length > 1 &&
          parts.skip(1).every((String part) => part.length == 3);
      if (looksLikeThousands) {
        return double.tryParse(parts.join());
      }
      return double.tryParse(value.replaceAll(',', '.'));
    }

    if (value.contains('.')) {
      final List<String> parts = value.split('.');
      final bool looksLikeThousands =
          parts.length > 1 &&
          parts.skip(1).every((String part) => part.length == 3);
      if (looksLikeThousands) {
        return double.tryParse(parts.join());
      }
    }

    return double.tryParse(value);
  }
}

class VoiceTransactionParseResult {
  const VoiceTransactionParseResult({
    required this.originalTranscript,
    required this.normalizedTranscript,
    required this.transactionType,
    required this.amount,
    required this.categoryUuid,
    required this.categoryName,
    required this.transactionDate,
    required this.description,
    required this.confidenceScore,
    required this.missingFields,
    required this.warnings,
    required this.amountCandidates,
    required this.transcriptLooksEmpty,
  });

  final String originalTranscript;
  final String normalizedTranscript;
  final String? transactionType;
  final double? amount;
  final String? categoryUuid;
  final String? categoryName;
  final DateTime transactionDate;
  final String description;
  final int confidenceScore;
  final List<String> missingFields;
  final List<String> warnings;
  final List<AmountCandidate> amountCandidates;
  final bool transcriptLooksEmpty;

  bool get hasAmount => amount != null && amount! > 0;

  bool get hasMissingRequiredFields =>
      missingFields.contains('amount') ||
      missingFields.contains('type') ||
      missingFields.contains('category');

  String get confidenceLabel {
    if (confidenceScore >= 80) {
      return 'Tinggi';
    }
    if (confidenceScore >= 50) {
      return 'Sedang';
    }
    return 'Rendah';
  }
}

class TransactionTypeDetection {
  const TransactionTypeDetection({
    required this.type,
    required this.incomeScore,
    required this.expenseScore,
    required this.warnings,
  });

  final String? type;
  final int incomeScore;
  final int expenseScore;
  final List<String> warnings;
}

class AmountExtraction {
  const AmountExtraction({
    required this.amount,
    required this.candidates,
    required this.isAmbiguous,
  });

  final double? amount;
  final List<AmountCandidate> candidates;
  final bool isAmbiguous;
}

class AmountCandidate {
  const AmountCandidate({
    required this.amount,
    required this.snippet,
    required this.start,
    required this.end,
    required this.priority,
  });

  final int amount;
  final String snippet;
  final int start;
  final int end;
  final int priority;
}

class CategoryDetection {
  const CategoryDetection({required this.category});

  final Category? category;
}

class DateExtraction {
  const DateExtraction({
    required this.transactionDate,
    required this.wasExplicitlyDetected,
    required this.warnings,
  });

  final DateTime transactionDate;
  final bool wasExplicitlyDetected;
  final List<String> warnings;
}

const List<String> _expenseKeywords = <String>[
  'beli',
  'bayar',
  'belanja',
  'keluar',
  'habis',
  'pengeluaran',
  'makan',
  'minum',
  'bensin',
  'ongkos',
  'top up',
  'topup',
  'transfer ke',
];

const List<String> _incomeKeywords = <String>[
  'gaji',
  'gajian',
  'dapat',
  'dapet',
  'menerima',
  'terima',
  'masuk',
  'pemasukan',
  'bonus',
  'dividen',
  'transfer dari',
  'dikirim',
  'pendapatan',
];

const List<String> _softExpenseKeywords = <String>[
  'untuk',
  'beliin',
  'tagihan',
  'listrik',
  'air',
  'internet',
  'pulsa',
];

const List<String> _softIncomeKeywords = <String>[
  'dari',
  'hadiah',
  'pemberian',
  'reward',
  'cashback',
];

const Map<String, List<String>> _expenseCategoryKeywords =
    <String, List<String>>{
      'Makanan': <String>['makan', 'nasi', 'kopi', 'minum', 'restoran'],
      'Makanan & Minuman': <String>[
        'makan',
        'nasi',
        'kopi',
        'minum',
        'restoran',
      ],
      'Transportasi': <String>[
        'bensin',
        'ojek',
        'grab',
        'gojek',
        'bus',
        'ongkos',
        'parkir',
      ],
      'Tagihan': <String>['listrik', 'air', 'internet', 'pulsa'],
      'Kesehatan': <String>['obat', 'dokter', 'rumah sakit'],
      'Pendidikan': <String>['buku', 'kuliah', 'kursus'],
      'Kuliah/Pendidikan': <String>['buku', 'kuliah', 'kursus', 'kampus'],
      'Belanja': <String>['belanja', 'bulanan', 'baju', 'sepatu'],
      'Kos/Asrama': <String>['kos', 'kost', 'asrama'],
      'Lainnya': <String>['sesuatu'],
    };

const Map<String, List<String>> _incomeCategoryKeywords =
    <String, List<String>>{
      'Gaji': <String>['gaji', 'gajian'],
      'Bonus': <String>['bonus'],
      'Dividen': <String>['dividen'],
      'Pemasukan Lainnya': <String>['hadiah', 'pemberian'],
      'Hadiah': <String>['hadiah', 'pemberian'],
      'Uang dari Orang Tua': <String>['mama', 'orang tua', 'ayah', 'ibu'],
      'Freelance/Part-time': <String>['freelance', 'part time', 'part-time'],
      'Bunga/Reward': <String>['reward', 'cashback', 'bunga'],
    };

const List<String> _numberWords = <String>[
  'setengah',
  'nol',
  'seratus',
  'seribu',
  'sejuta',
  'satu',
  'dua',
  'tiga',
  'empat',
  'lima',
  'enam',
  'tujuh',
  'delapan',
  'sembilan',
  'sepuluh',
  'sebelas',
  'belas',
  'puluh',
  'ratus',
  'ribu',
  'juta',
];
