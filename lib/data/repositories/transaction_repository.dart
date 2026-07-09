import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/category.dart';
import '../models/money_transaction.dart';

class TransactionRepository {
  TransactionRepository(this._isar);

  final Isar _isar;

  Future<MoneyTransaction> createTransaction({
    required String type,
    required String title,
    required double amount,
    required String categoryUuid,
    String paymentMethod = 'Tidak Dicatat',
    String? note,
    required String source,
    required DateTime transactionDate,
  }) async {
    final Category category = await _requireCategory(categoryUuid);
    final DateTime now = DateTimeUtils.utcNow();
    final MoneyTransaction transaction = MoneyTransaction(
      uuid: IdGenerator.newUuid(),
      type: type,
      title: title.trim(),
      amount: amount,
      categoryUuid: categoryUuid,
      categoryNameSnapshot: category.name,
      paymentMethod: paymentMethod.trim().isEmpty
          ? 'Tidak Dicatat'
          : paymentMethod.trim(),
      note: _normalizeNullable(note),
      source: source,
      syncStatus: 'pending',
      transactionDate: DateTimeUtils.normalizeUtc(transactionDate),
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.moneyTransactions.put(transaction);
    });

    return transaction;
  }

  Future<MoneyTransaction> updateTransaction(
    MoneyTransaction transaction,
  ) async {
    final Category category = await _requireCategory(transaction.categoryUuid);
    transaction.title = transaction.title.trim();
    transaction.note = _normalizeNullable(transaction.note);
    transaction.paymentMethod = transaction.paymentMethod.trim().isEmpty
        ? 'Tidak Dicatat'
        : transaction.paymentMethod.trim();
    transaction.categoryNameSnapshot = category.name;
    transaction.transactionDate = DateTimeUtils.normalizeUtc(
      transaction.transactionDate,
    );
    transaction.updatedAt = DateTimeUtils.utcNow();
    transaction.deletedAt = transaction.isDeleted
        ? (transaction.deletedAt == null
              ? transaction.updatedAt
              : DateTimeUtils.normalizeUtc(transaction.deletedAt!))
        : null;

    await _isar.writeTxn(() async {
      await _isar.moneyTransactions.put(transaction);
    });

    return transaction;
  }

  Future<void> softDeleteTransaction(String uuid) async {
    final MoneyTransaction? transaction = await _isar.moneyTransactions
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (transaction == null || transaction.isDeleted) {
      return;
    }

    final DateTime now = DateTimeUtils.utcNow();
    transaction.isDeleted = true;
    transaction.deletedAt = now;
    transaction.updatedAt = now;
    transaction.syncStatus = 'pending';

    await _isar.writeTxn(() async {
      await _isar.moneyTransactions.put(transaction);
    });
  }

  Future<List<MoneyTransaction>> getRecentTransactions({int limit = 10}) {
    return _isar.moneyTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByTransactionDateDesc()
        .thenByUpdatedAtDesc()
        .limit(limit)
        .findAll();
  }

  Future<List<MoneyTransaction>> getTransactionsByMonth(DateTime month) {
    final DateTime monthUtc = DateTime.utc(month.year, month.month);
    final DateTime nextMonth = DateTime.utc(month.year, month.month + 1);

    return _isar.moneyTransactions
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .transactionDateGreaterThan(monthUtc, include: true)
        .and()
        .transactionDateLessThan(nextMonth, include: false)
        .sortByTransactionDateDesc()
        .findAll();
  }

  Future<List<MoneyTransaction>> getPendingSyncTransactions() {
    return _isar.moneyTransactions
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .syncStatusEqualTo('pending')
        .sortByUpdatedAt()
        .findAll();
  }

  Future<MoneyTransaction?> getByUuid(String uuid) {
    return _isar.moneyTransactions.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<Category> _requireCategory(String categoryUuid) async {
    final Category? category = await _isar.categorys
        .filter()
        .uuidEqualTo(categoryUuid)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
    if (category == null) {
      throw StateError('Kategori tidak ditemukan atau sudah dihapus.');
    }
    return category;
  }

  String? _normalizeNullable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
