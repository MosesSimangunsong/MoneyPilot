import '../../data/models/money_transaction.dart';
import 'date_formatter.dart';

class TransactionDateGroup {
  const TransactionDateGroup({
    required this.label,
    required this.date,
    required this.transactions,
  });

  final String label;
  final DateTime date;
  final List<MoneyTransaction> transactions;
}

class TransactionDateGrouping {
  const TransactionDateGrouping._();

  static List<TransactionDateGroup> groupTransactions(
    List<MoneyTransaction> transactions, {
    DateTime? referenceDate,
  }) {
    final DateTime baseDate = (referenceDate ?? DateTime.now()).toLocal();
    final DateTime today = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
    );
    final List<TransactionDateGroup> groups = <TransactionDateGroup>[];

    for (final MoneyTransaction transaction in transactions) {
      final DateTime localDate = transaction.transactionDate.toLocal();
      final DateTime groupDate = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
      );

      if (groups.isNotEmpty && _isSameDay(groups.last.date, groupDate)) {
        groups.last.transactions.add(transaction);
        continue;
      }

      groups.add(
        TransactionDateGroup(
          label: _labelForDate(groupDate, today),
          date: groupDate,
          transactions: <MoneyTransaction>[transaction],
        ),
      );
    }

    return groups;
  }

  static String _labelForDate(DateTime value, DateTime today) {
    if (_isSameDay(value, today)) {
      return 'Hari ini';
    }

    final DateTime yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(value, yesterday)) {
      return 'Kemarin';
    }

    return DateFormatter.formatShortDate(value);
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
