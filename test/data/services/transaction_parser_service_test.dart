import 'package:app/data/models/category.dart';
import 'package:app/data/services/transaction_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TransactionParserService parser = TransactionParserService();
  final List<Category> categories = <Category>[
    _category('expense-food', 'Makanan & Minuman', 'expense'),
    _category('expense-transport', 'Transportasi', 'expense'),
    _category('expense-kos', 'Kos/Asrama', 'expense'),
    _category('expense-study', 'Kuliah/Pendidikan', 'expense'),
    _category('expense-other', 'Lainnya', 'expense'),
    _category('income-parent', 'Uang dari Orang Tua', 'income'),
    _category('income-freelance', 'Freelance/Part-time', 'income'),
    _category('income-scholarship', 'Beasiswa', 'income'),
    _category('income-salary', 'Gaji', 'income'),
    _category('income-dividend', 'Dividen', 'income'),
  ];

  group('TransactionParserService', () {
    test('parse pengeluaran valid', () {
      final result = parser.parse(
        rawText: 'Saya beli kopi 15 ribu',
        categories: categories,
      );

      expect(result.type, 'expense');
      expect(result.amount, 15000);
      expect(result.categoryName, 'Makanan & Minuman');
      expect(result.shouldOpenManualForm, isFalse);
    });

    test('parse pemasukan valid', () {
      final result = parser.parse(
        rawText: 'Dapat uang dari orang tua lima ratus ribu',
        categories: categories,
      );

      expect(result.type, 'income');
      expect(result.amount, 500000);
      expect(result.categoryName, 'Uang dari Orang Tua');
    });

    test('nominal gagal membuka form manual', () {
      final result = parser.parse(
        rawText: 'Saya beli kopi tadi pagi',
        categories: categories,
      );

      expect(result.amount, isNull);
      expect(result.shouldOpenManualForm, isTrue);
      expect(result.note, 'Saya beli kopi tadi pagi');
    });

    test('kalimat ambigu tidak memaksa tipe transaksi', () {
      final result = parser.parse(
        rawText: 'Transfer lima puluh ribu',
        categories: categories,
      );

      expect(result.type, isNull);
      expect(result.amount, 50000);
      expect(result.shouldOpenManualForm, isFalse);
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
