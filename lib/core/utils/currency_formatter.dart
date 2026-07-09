class CurrencyFormatter {
  const CurrencyFormatter._();

  static String formatRupiah(num amount) {
    final bool isNegative = amount < 0;
    final int absoluteValue = amount.abs().round();
    final String digits = absoluteValue.toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final int reverseIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    final String formatted = buffer.toString();
    return '${isNegative ? '-' : ''}Rp$formatted';
  }
}
