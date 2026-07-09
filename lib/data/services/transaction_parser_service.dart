import '../../core/utils/indonesian_number_parser.dart';
import '../models/category.dart';

class TransactionParserService {
  const TransactionParserService();

  ParsedVoiceTransaction parse({
    required String rawText,
    required List<Category> categories,
  }) {
    final String normalized = _normalize(rawText);
    final double? amount = IndonesianNumberParser.parse(normalized);
    final String? type = _detectType(normalized);
    final Category? category = _detectCategory(
      normalized: normalized,
      type: type,
      categories: categories,
    );
    final String title = _extractTitle(rawText, normalized);

    double confidence = 0.1;
    if (amount != null) {
      confidence += 0.45;
    }
    if (type != null) {
      confidence += 0.2;
    }
    if (category != null) {
      confidence += 0.15;
    }
    if (title.isNotEmpty && title != rawText.trim()) {
      confidence += 0.1;
    }
    if (type == null && _containsAny(normalized, _ambiguousTypeKeywords)) {
      confidence -= 0.05;
    }

    return ParsedVoiceTransaction(
      rawText: rawText.trim(),
      title: title.isEmpty ? rawText.trim() : title,
      amount: amount,
      type: type,
      categoryUuid: category?.uuid,
      categoryName: category?.name,
      note: amount == null ? rawText.trim() : null,
      confidenceScore: confidence.clamp(0.0, 1.0),
      shouldOpenManualForm: amount == null,
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9,\.\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _detectType(String normalized) {
    if (_containsAny(normalized, _ambiguousTypeKeywords) &&
        !_containsAny(normalized, _incomeKeywords) &&
        !_containsAny(normalized, _expenseKeywords)) {
      return null;
    }

    final bool isIncome = _containsAny(normalized, _incomeKeywords);
    final bool isExpense = _containsAny(normalized, _expenseKeywords);

    if (isIncome == isExpense) {
      return null;
    }

    return isIncome ? 'income' : 'expense';
  }

  Category? _detectCategory({
    required String normalized,
    required String? type,
    required List<Category> categories,
  }) {
    if (type == null) {
      return null;
    }

    final Map<String, List<String>> keywordMap = type == 'income'
        ? _incomeCategoryKeywords
        : _expenseCategoryKeywords;

    for (final MapEntry<String, List<String>> entry in keywordMap.entries) {
      if (_containsAny(normalized, entry.value)) {
        return _findCategoryByName(categories, entry.key);
      }
    }

    return null;
  }

  String _extractTitle(String rawText, String normalized) {
    String cleaned = normalized;
    for (final String pattern in <String>[
      ..._expenseKeywords,
      ..._incomeKeywords,
      ..._ambiguousTypeKeywords,
      'saya',
      'aku',
      'uang',
      'dari',
      'untuk',
      'ke',
      'masuk',
      'tadi',
      'pagi',
      'siang',
      'malam',
      'hari ini',
    ]) {
      cleaned = cleaned.replaceAll(RegExp('\\b$pattern\\b'), ' ');
    }

    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d[\d.,]*\s*(juta|ribu|rb|k)?\b'),
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
      return rawText.trim();
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

  Category? _findCategoryByName(List<Category> categories, String name) {
    for (final Category category in categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  bool _containsAny(String normalized, List<String> keywords) {
    return keywords.any(
      (String keyword) =>
          RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(normalized),
    );
  }
}

class ParsedVoiceTransaction {
  const ParsedVoiceTransaction({
    required this.rawText,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryUuid,
    required this.categoryName,
    required this.note,
    required this.confidenceScore,
    required this.shouldOpenManualForm,
  });

  final String rawText;
  final String title;
  final double? amount;
  final String? type;
  final String? categoryUuid;
  final String? categoryName;
  final String? note;
  final double confidenceScore;
  final bool shouldOpenManualForm;
}

const List<String> _expenseKeywords = <String>[
  'beli',
  'bayar',
  'naik',
  'top up',
  'topup',
  'keluar',
  'keluarin',
  'jajan',
];

const List<String> _incomeKeywords = <String>[
  'dapat',
  'dapet',
  'terima',
  'gajian',
  'gaji',
  'beasiswa',
  'dividen',
  'freelance',
  'part time',
  'part-time',
  'hadiah',
];

const List<String> _ambiguousTypeKeywords = <String>['transfer', 'uang masuk'];

const Map<String, List<String>> _expenseCategoryKeywords =
    <String, List<String>>{
      'Makanan & Minuman': <String>['kopi', 'makan', 'nasi', 'minum', 'snack'],
      'Transportasi': <String>[
        'gojek',
        'grab',
        'transport',
        'bensin',
        'parkir',
        'bus',
      ],
      'Kos/Asrama': <String>['kos', 'kost', 'asrama', 'kontrakan'],
      'Kuliah/Pendidikan': <String>[
        'kuliah',
        'kampus',
        'buku',
        'pendidikan',
        'spp',
      ],
      'Hiburan': <String>['hiburan', 'nonton', 'game', 'film'],
      'Kesehatan': <String>['obat', 'dokter', 'rumah sakit', 'kesehatan'],
      'Belanja': <String>['belanja', 'baju', 'sepatu', 'celana'],
      'Investasi': <String>['investasi', 'saham', 'reksa'],
      'Tabungan': <String>['tabung', 'tabungan'],
      'Lainnya': <String>['e wallet', 'e-wallet', 'ewallet', 'sesuatu'],
    };

const Map<String, List<String>> _incomeCategoryKeywords =
    <String, List<String>>{
      'Uang dari Orang Tua': <String>['orang tua', 'ortu', 'ayah', 'ibu'],
      'Freelance/Part-time': <String>[
        'freelance',
        'part time',
        'part-time',
        'proyek',
      ],
      'Beasiswa': <String>['beasiswa'],
      'Gaji': <String>['gaji', 'gajian'],
      'Dividen': <String>['dividen'],
      'Bunga/Reward': <String>['bunga', 'reward', 'cashback'],
      'Hadiah': <String>['hadiah', 'bonus'],
    };
