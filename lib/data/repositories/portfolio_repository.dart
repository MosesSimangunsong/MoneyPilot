import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/dividend.dart';
import '../models/stock_transaction.dart';
import '../models/watchlist_item.dart';

class PortfolioRepository {
  PortfolioRepository(this._isar);

  final Isar _isar;

  Future<StockTransaction> createStockTransaction({
    required String symbol,
    String? companyName,
    required String actionType,
    required int lot,
    required int shares,
    required double price,
    required double fee,
    required DateTime transactionDate,
    String? note,
  }) async {
    final DateTime now = DateTimeUtils.utcNow();
    final StockTransaction transaction = StockTransaction(
      uuid: IdGenerator.newUuid(),
      symbol: symbol.trim().toUpperCase(),
      companyName: _normalizeNullable(companyName),
      actionType: actionType,
      lot: lot,
      shares: shares,
      price: price,
      fee: fee,
      transactionDate: DateTimeUtils.normalizeUtc(transactionDate),
      note: _normalizeNullable(note),
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.stockTransactions.put(transaction);
    });

    return transaction;
  }

  Future<StockTransaction> updateStockTransaction(
    StockTransaction transaction,
  ) async {
    transaction.symbol = transaction.symbol.trim().toUpperCase();
    transaction.companyName = _normalizeNullable(transaction.companyName);
    transaction.note = _normalizeNullable(transaction.note);
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
      await _isar.stockTransactions.put(transaction);
    });

    return transaction;
  }

  Future<void> softDeleteStockTransaction(String uuid) async {
    final StockTransaction? transaction = await _isar.stockTransactions
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
      await _isar.stockTransactions.put(transaction);
    });
  }

  Future<Dividend> createDividend({
    required String symbol,
    String? companyName,
    required double grossAmount,
    required double tax,
    required double netAmount,
    required DateTime receivedDate,
    String? linkedTransactionUuid,
    String? note,
  }) async {
    final DateTime now = DateTimeUtils.utcNow();
    final Dividend dividend = Dividend(
      uuid: IdGenerator.newUuid(),
      symbol: symbol.trim().toUpperCase(),
      companyName: _normalizeNullable(companyName),
      grossAmount: grossAmount,
      tax: tax,
      netAmount: netAmount,
      receivedDate: DateTimeUtils.normalizeUtc(receivedDate),
      linkedTransactionUuid: _normalizeNullable(linkedTransactionUuid),
      note: _normalizeNullable(note),
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.dividends.put(dividend);
    });

    return dividend;
  }

  Future<Dividend> updateDividend(Dividend dividend) async {
    dividend.symbol = dividend.symbol.trim().toUpperCase();
    dividend.companyName = _normalizeNullable(dividend.companyName);
    dividend.linkedTransactionUuid = _normalizeNullable(
      dividend.linkedTransactionUuid,
    );
    dividend.note = _normalizeNullable(dividend.note);
    dividend.receivedDate = DateTimeUtils.normalizeUtc(dividend.receivedDate);
    dividend.updatedAt = DateTimeUtils.utcNow();
    dividend.deletedAt = dividend.isDeleted
        ? (dividend.deletedAt == null
              ? dividend.updatedAt
              : DateTimeUtils.normalizeUtc(dividend.deletedAt!))
        : null;

    await _isar.writeTxn(() async {
      await _isar.dividends.put(dividend);
    });

    return dividend;
  }

  Future<void> softDeleteDividend(String uuid) async {
    final Dividend? dividend = await _isar.dividends
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (dividend == null || dividend.isDeleted) {
      return;
    }

    final DateTime now = DateTimeUtils.utcNow();
    dividend.isDeleted = true;
    dividend.deletedAt = now;
    dividend.updatedAt = now;
    dividend.syncStatus = 'pending';

    await _isar.writeTxn(() async {
      await _isar.dividends.put(dividend);
    });
  }

  Future<List<StockTransaction>> getActiveStockTransactions() {
    return _isar.stockTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByTransactionDateDesc()
        .findAll();
  }

  Future<List<Dividend>> getActiveDividends() {
    return _isar.dividends
        .filter()
        .isDeletedEqualTo(false)
        .sortByReceivedDateDesc()
        .findAll();
  }

  Future<List<WatchlistItem>> getWatchlist() {
    return _isar.watchlistItems
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<WatchlistItem> upsertWatchlistItem(WatchlistItem item) async {
    final DateTime now = DateTimeUtils.utcNow();
    item.symbol = item.symbol.trim().toUpperCase();
    item.companyName = _normalizeNullable(item.companyName);
    item.note = _normalizeNullable(item.note);
    item.createdAt = DateTimeUtils.normalizeUtc(item.createdAt);
    item.updatedAt = now;
    item.deletedAt = item.isDeleted
        ? (item.deletedAt == null
              ? now
              : DateTimeUtils.normalizeUtc(item.deletedAt!))
        : null;
    item.uuid = item.uuid.trim().isEmpty ? IdGenerator.newUuid() : item.uuid;

    await _isar.writeTxn(() async {
      await _isar.watchlistItems.put(item);
    });

    return item;
  }

  Future<void> softDeleteWatchlistItem(String uuid) async {
    final WatchlistItem? item = await _isar.watchlistItems
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (item == null || item.isDeleted) {
      return;
    }

    final DateTime now = DateTimeUtils.utcNow();
    item.isDeleted = true;
    item.deletedAt = now;
    item.updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.watchlistItems.put(item);
    });
  }

  String? _normalizeNullable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
