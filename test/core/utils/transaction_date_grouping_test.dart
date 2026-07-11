import 'package:app/core/utils/transaction_date_grouping.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transaksi hari yang sama masuk grup yang sama', () {
    final List<MoneyTransaction> transactions = <MoneyTransaction>[
      _transaction(
        uuid: '1',
        title: 'Sarapan',
        date: DateTime.utc(2026, 7, 11, 12),
      ),
      _transaction(
        uuid: '2',
        title: 'Makan malam',
        date: DateTime.utc(2026, 7, 11, 14),
      ),
      _transaction(
        uuid: '3',
        title: 'Transport',
        date: DateTime.utc(2026, 7, 10, 12),
      ),
    ];

    final List<TransactionDateGroup> groups =
        TransactionDateGrouping.groupTransactions(
          transactions,
          referenceDate: DateTime.utc(2026, 7, 11, 12),
        );

    expect(groups, hasLength(2));
    expect(groups.first.label, 'Hari ini');
    expect(groups.first.transactions, hasLength(2));
    expect(groups.last.label, 'Kemarin');
  });

  test('urutan transaksi tidak berubah', () {
    final List<MoneyTransaction> transactions = <MoneyTransaction>[
      _transaction(
        uuid: '1',
        title: 'Pertama',
        date: DateTime.utc(2026, 7, 11, 12),
      ),
      _transaction(
        uuid: '2',
        title: 'Kedua',
        date: DateTime.utc(2026, 7, 11, 11),
      ),
      _transaction(
        uuid: '3',
        title: 'Ketiga',
        date: DateTime.utc(2026, 7, 10, 12),
      ),
    ];

    final List<TransactionDateGroup> groups =
        TransactionDateGrouping.groupTransactions(
          transactions,
          referenceDate: DateTime.utc(2026, 7, 11, 12),
        );

    expect(
      groups.first.transactions.map((MoneyTransaction item) => item.uuid),
      <String>['1', '2'],
    );
    expect(groups.last.transactions.single.uuid, '3');
  });

  test('label hari ini kemarin dan tanggal lain deterministik', () {
    final List<MoneyTransaction> transactions = <MoneyTransaction>[
      _transaction(
        uuid: '1',
        title: 'Hari ini',
        date: DateTime.utc(2026, 7, 11, 12),
      ),
      _transaction(
        uuid: '2',
        title: 'Kemarin',
        date: DateTime.utc(2026, 7, 10, 12),
      ),
      _transaction(
        uuid: '3',
        title: 'Lama',
        date: DateTime.utc(2026, 7, 8, 12),
      ),
    ];

    final List<TransactionDateGroup> groups =
        TransactionDateGrouping.groupTransactions(
          transactions,
          referenceDate: DateTime.utc(2026, 7, 11, 12),
        );

    expect(groups[0].label, 'Hari ini');
    expect(groups[1].label, 'Kemarin');
    expect(groups[2].label, '8 Jul 2026');
  });
}

MoneyTransaction _transaction({
  required String uuid,
  required String title,
  required DateTime date,
}) {
  return MoneyTransaction(
    uuid: uuid,
    type: 'expense',
    title: title,
    amount: 10000,
    categoryUuid: 'cat-1',
    categoryNameSnapshot: 'Makanan & Minuman',
    source: 'manual',
    transactionDate: date,
    createdAt: date,
    updatedAt: date,
  );
}
