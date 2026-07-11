import 'package:app/data/models/category.dart';
import 'package:app/data/services/transaction_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TransactionParserService parser = TransactionParserService();
  final List<Category> categories = <Category>[
    _category('expense-food', 'Makanan & Minuman', 'expense'),
    _category('expense-transport', 'Transportasi', 'expense'),
    _category('expense-bill', 'Tagihan', 'expense'),
    _category('expense-health', 'Kesehatan', 'expense'),
    _category('expense-study', 'Kuliah/Pendidikan', 'expense'),
    _category('expense-shopping', 'Belanja', 'expense'),
    _category('expense-other', 'Lainnya', 'expense'),
    _category('income-parent', 'Uang dari Orang Tua', 'income'),
    _category('income-freelance', 'Freelance/Part-time', 'income'),
    _category('income-salary', 'Gaji', 'income'),
    _category('income-dividend', 'Dividen', 'income'),
    _category('income-other', 'Hadiah', 'income'),
  ];

  group('TransactionParserService', () {
    test('parse pengeluaran valid', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'beli kopi dua puluh lima ribu',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.transactionType, 'expense');
      expect(result.amount, 25000);
      expect(result.categoryName, 'Makanan & Minuman');
      expect(result.missingFields, isNot(contains('amount')));
    });

    test('parse pemasukan gajian', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'gajian satu juta',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.transactionType, 'income');
      expect(result.amount, 1000000);
      expect(result.categoryName, 'Gaji');
      expect(result.confidenceScore, greaterThanOrEqualTo(80));
    });

    test('parse bensin dan kategori transportasi', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'bayar bensin 50 ribu',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.transactionType, 'expense');
      expect(result.amount, 50000);
      expect(result.categoryName, 'Transportasi');
    });

    test('parse dividen', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'dividen bbca tiga ratus ribu',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.transactionType, 'income');
      expect(result.amount, 300000);
      expect(result.categoryName, 'Dividen');
      expect(result.description.toLowerCase(), contains('bbca'));
    });

    test('nominal hilang ditandai sebagai missing field', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'beli makan',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.amount, isNull);
      expect(result.missingFields, contains('amount'));
      expect(result.warnings, contains('Nominal belum dikenali.'));
    });

    test('kemarin diparse sebagai tanggal kemarin', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText: 'kemarin bayar listrik seratus ribu',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.transactionType, 'expense');
      expect(result.amount, 100000);
      expect(result.transactionDate.toLocal().year, 2026);
      expect(result.transactionDate.toLocal().month, 7);
      expect(result.transactionDate.toLocal().day, 10);
      expect(result.categoryName, 'Tagihan');
    });

    test('nominal ganda memilih total dan memberi warning', () {
      final VoiceTransactionParseResult result = parser.parse(
        rawText:
            'beli dua kopi masing masing dua puluh ribu total empat puluh ribu',
        categories: categories,
        referenceTime: DateTime(2026, 7, 11, 10),
      );

      expect(result.amount, 40000);
      expect(
        result.warnings.join(' '),
        contains('lebih dari satu kandidat nominal'),
      );
    });
  });
}

Category _category(String uuid, String name, String type) {
  return Category(
    uuid: uuid,
    name: name,
    type: type,
    iconName: 'icon',
    colorHex: '#000000',
    createdAt: DateTime.utc(2026, 7, 9),
    updatedAt: DateTime.utc(2026, 7, 9),
  );
}
