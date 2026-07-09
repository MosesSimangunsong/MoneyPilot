import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/category.dart';
import '../models/money_transaction.dart';

class TransactionRepository {
  TransactionRepository(this._isar);

  final Isar _isar;

  Stream<void> watchTransactions() {
    return _isar.moneyTransactions.watchLazy(fireImmediately: true);
  }

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
    final Category category = await _requireCategoryForType(categoryUuid, type);
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

    return _normalizeTransactionDates(transaction);
  }

  Future<MoneyTransaction> updateTransaction({
    required String uuid,
    required String type,
    required String title,
    required double amount,
    required String categoryUuid,
    required DateTime transactionDate,
    String paymentMethod = 'Tidak Dicatat',
    String? note,
  }) async {
    final MoneyTransaction? transaction = await getByUuid(uuid);
    if (transaction == null || transaction.isDeleted) {
      throw StateError('Transaksi tidak ditemukan atau sudah dihapus.');
    }

    final Category category = await _requireCategoryForType(categoryUuid, type);
    final bool categoryChanged = transaction.categoryUuid != categoryUuid;

    transaction.type = type;
    transaction.title = title.trim();
    transaction.amount = amount;
    transaction.categoryUuid = categoryUuid;
    transaction.note = _normalizeNullable(note);
    transaction.paymentMethod = paymentMethod.trim().isEmpty
        ? 'Tidak Dicatat'
        : paymentMethod.trim();
    if (categoryChanged || transaction.categoryNameSnapshot.trim().isEmpty) {
      transaction.categoryNameSnapshot = category.name;
    }
    transaction.transactionDate = DateTimeUtils.normalizeUtc(transactionDate);
    transaction.updatedAt = DateTimeUtils.utcNow();
    transaction.syncStatus = 'pending';
    transaction.syncErrorMessage = null;
    transaction.isDeleted = false;
    transaction.deletedAt = null;

    await _isar.writeTxn(() async {
      await _isar.moneyTransactions.put(transaction);
    });

    return _normalizeTransactionDates(transaction);
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
    return getActiveTransactions(limit: limit);
  }

  Future<List<MoneyTransaction>> getActiveTransactions({
    String? type,
    int? limit,
  }) {
    var query = _isar.moneyTransactions.filter().isDeletedEqualTo(false);
    if (type != null) {
      query = query.and().typeEqualTo(type);
    }

    if (limit != null) {
      return query
          .sortByTransactionDateDesc()
          .thenByUpdatedAtDesc()
          .limit(limit)
          .findAll()
          .then(_normalizeTransactionList);
    }

    return query
        .sortByTransactionDateDesc()
        .thenByUpdatedAtDesc()
        .findAll()
        .then(_normalizeTransactionList);
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
        .findAll()
        .then(_normalizeTransactionList);
  }

  Future<List<MoneyTransaction>> getPendingSyncTransactions() {
    return _isar.moneyTransactions
        .filter()
        .syncStatusEqualTo('pending')
        .sortByUpdatedAt()
        .findAll()
        .then(_normalizeTransactionList);
  }

  Future<MonthlyTransactionSummary> getMonthlySummary(
    DateTime month, {
    int recentLimit = 5,
  }) async {
    final List<MoneyTransaction> transactions = await getTransactionsByMonth(
      month,
    );
    double incomeTotal = 0;
    double expenseTotal = 0;

    for (final MoneyTransaction transaction in transactions) {
      if (transaction.type == 'income') {
        incomeTotal += transaction.amount;
      } else if (transaction.type == 'expense') {
        expenseTotal += transaction.amount;
      }
    }

    return MonthlyTransactionSummary(
      month: DateTime.utc(month.year, month.month),
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      transactionCount: transactions.length,
      recentTransactions: transactions.take(recentLimit).toList(),
    );
  }

  Future<MoneyTransaction?> getByUuid(String uuid) {
    return _isar.moneyTransactions.filter().uuidEqualTo(uuid).findFirst().then((
      MoneyTransaction? item,
    ) {
      if (item == null) {
        return null;
      }
      return _normalizeTransactionDates(item);
    });
  }

  Future<Category> _requireCategoryForType(
    String categoryUuid,
    String type,
  ) async {
    final Category? category = await _isar.categorys
        .filter()
        .uuidEqualTo(categoryUuid)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
    if (category == null) {
      throw StateError('Kategori tidak ditemukan atau sudah dihapus.');
    }
    if (category.type != type) {
      throw StateError('Kategori tidak sesuai dengan tipe transaksi.');
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

  List<MoneyTransaction> _normalizeTransactionList(
    List<MoneyTransaction> items,
  ) {
    return items.map(_normalizeTransactionDates).toList(growable: false);
  }

  MoneyTransaction _normalizeTransactionDates(MoneyTransaction transaction) {
    transaction.transactionDate = DateTimeUtils.normalizeUtc(
      transaction.transactionDate,
    );
    transaction.createdAt = DateTimeUtils.normalizeUtc(transaction.createdAt);
    transaction.updatedAt = DateTimeUtils.normalizeUtc(transaction.updatedAt);
    if (transaction.deletedAt != null) {
      transaction.deletedAt = DateTimeUtils.normalizeUtc(
        transaction.deletedAt!,
      );
    }
    return transaction;
  }
}

class MonthlyTransactionSummary {
  const MonthlyTransactionSummary({
    required this.month,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transactionCount,
    required this.recentTransactions,
  });

  final DateTime month;
  final double incomeTotal;
  final double expenseTotal;
  final int transactionCount;
  final List<MoneyTransaction> recentTransactions;

  double get cashflow => incomeTotal - expenseTotal;

  bool get isEmpty => transactionCount == 0;
}
