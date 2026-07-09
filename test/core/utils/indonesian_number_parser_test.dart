import 'package:app/core/utils/indonesian_number_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndonesianNumberParser', () {
    test('parse angka ribuan umum', () {
      expect(IndonesianNumberParser.parse('15000'), 15000);
      expect(IndonesianNumberParser.parse('15.000'), 15000);
      expect(IndonesianNumberParser.parse('15,000'), 15000);
      expect(IndonesianNumberParser.parse('15 ribu'), 15000);
      expect(IndonesianNumberParser.parse('15 rb'), 15000);
      expect(IndonesianNumberParser.parse('15k'), 15000);
    });

    test('parse angka bahasa Indonesia', () {
      expect(IndonesianNumberParser.parse('dua puluh lima ribu'), 25000);
      expect(IndonesianNumberParser.parse('seratus ribu'), 100000);
      expect(IndonesianNumberParser.parse('lima ratus ribu'), 500000);
      expect(IndonesianNumberParser.parse('satu juta'), 1000000);
      expect(IndonesianNumberParser.parse('1 juta'), 1000000);
      expect(IndonesianNumberParser.parse('1,5 juta'), 1500000);
      expect(IndonesianNumberParser.parse('setengah juta'), 500000);
    });

    test('return null jika input kosong', () {
      expect(IndonesianNumberParser.parse(''), isNull);
      expect(IndonesianNumberParser.parse('uang'), isNull);
    });
  });
}
