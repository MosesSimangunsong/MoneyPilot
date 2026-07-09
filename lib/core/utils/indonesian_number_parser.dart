class IndonesianNumberParser {
  const IndonesianNumberParser._();

  static const Map<String, int> _basicNumbers = <String, int>{
    'nol': 0,
    'satu': 1,
    'se': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
  };

  static const Map<String, int> _scales = <String, int>{
    'ribu': 1000,
    'rb': 1000,
    'k': 1000,
    'juta': 1000000,
  };

  static double? parse(String? rawInput) {
    final String normalized = _normalizeInput(rawInput);
    if (normalized.isEmpty) {
      return null;
    }

    final double? direct = _parseDirectNumericExpression(normalized);
    if (direct != null) {
      return direct;
    }

    if (normalized.contains('setengah juta')) {
      return 500000;
    }

    final List<String> tokens = normalized
        .split(' ')
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return null;
    }

    double total = 0;
    double current = 0;

    for (int index = 0; index < tokens.length; index++) {
      final String token = tokens[index];

      if (_basicNumbers.containsKey(token)) {
        current += _basicNumbers[token]!.toDouble();
        continue;
      }

      if (token == 'belas') {
        if (current == 0) {
          return null;
        }
        current += 10;
        continue;
      }

      if (token == 'puluh') {
        current = current == 0 ? 10 : current * 10;
        continue;
      }

      if (token == 'ratus') {
        current = current == 0 ? 100 : current * 100;
        continue;
      }

      final int? scale = _scales[token];
      if (scale != null) {
        final double multiplier = current == 0 ? 1 : current;
        total += multiplier * scale;
        current = 0;
        continue;
      }

      if (double.tryParse(token) != null) {
        current += double.parse(token);
        continue;
      }
    }

    final double result = total + current;
    if (result <= 0) {
      return null;
    }

    return result;
  }

  static String _normalizeInput(String? rawInput) {
    return (rawInput ?? '')
        .toLowerCase()
        .replaceAll('seratus', 'satu ratus')
        .replaceAll('seribu', 'satu ribu')
        .replaceAll('sejuta', 'satu juta')
        .replaceAll(RegExp(r'[^a-z0-9,\.\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double? _parseDirectNumericExpression(String normalized) {
    final RegExp scaledPattern = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(juta|ribu|rb|k)\b',
    );
    final Match? scaledMatch = scaledPattern.firstMatch(normalized);
    if (scaledMatch != null) {
      final double? value = _parseLocaleNumber(scaledMatch.group(1)!);
      final int scale = _scales[scaledMatch.group(2)!]!;
      if (value == null) {
        return null;
      }
      return value * scale;
    }

    final RegExp plainPattern = RegExp(r'\d[\d.,]*');
    final Match? plainMatch = plainPattern.firstMatch(normalized);
    if (plainMatch == null) {
      return null;
    }

    return _parseUngroupedNumber(plainMatch.group(0)!);
  }

  static double? _parseLocaleNumber(String value) {
    final String normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static double? _parseUngroupedNumber(String value) {
    if (value.contains('.') && value.contains(',')) {
      return double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
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

    return double.tryParse(value);
  }
}
