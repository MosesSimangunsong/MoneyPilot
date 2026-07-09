class DateFormatter {
  const DateFormatter._();

  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String formatShortDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
  }

  static String formatMonthYear(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_monthNames[local.month - 1]} ${local.year}';
  }
}
