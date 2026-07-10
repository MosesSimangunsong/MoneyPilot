import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/watchlist_item.dart';
import 'category_repository.dart';

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
      actionType: _normalizeActionType(actionType),
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
    String uuid, {
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
    final StockTransaction? transaction = await getStockTransactionByUuid(uuid);
    if (transaction == null || transaction.isDeleted) {
      throw StateError('Transaksi saham tidak ditemukan atau sudah dihapus.');
    }

    transaction.symbol = symbol.trim().toUpperCase();
    transaction.companyName = _normalizeNullable(companyName);
    transaction.actionType = _normalizeActionType(actionType);
    transaction.lot = lot;
    transaction.shares = shares;
    transaction.price = price;
    transaction.fee = fee;
    transaction.note = _normalizeNullable(note);
    transaction.transactionDate = DateTimeUtils.normalizeUtc(transactionDate);
    transaction.updatedAt = DateTimeUtils.utcNow();
    transaction.syncStatus = 'pending';
    transaction.syncErrorMessage = null;
    transaction.isDeleted = false;
    transaction.deletedAt = null;

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

  Future<DividendWithIncomeResult> createDividendWithIncomeTransaction({
    required String symbol,
    String? companyName,
    double? grossAmount,
    double tax = 0,
    required double netAmount,
    required DateTime receivedDate,
    String? note,
  }) async {
    final DateTime now = DateTimeUtils.utcNow();
    final Category dividendCategory = await _resolveDividendCategory();
    final String normalizedSymbol = symbol.trim().toUpperCase();
    final double normalizedGrossAmount = grossAmount ?? (netAmount + tax);
    final String? normalizedCompanyName = _normalizeNullable(companyName);
    final String? normalizedNote = _normalizeNullable(note);
    final MoneyTransaction moneyTransaction = MoneyTransaction(
      uuid: IdGenerator.newUuid(),
      type: 'income',
      title: 'Dividen $normalizedSymbol',
      amount: netAmount,
      categoryUuid: dividendCategory.uuid,
      categoryNameSnapshot: dividendCategory.name,
      paymentMethod: 'Tidak Dicatat',
      note: normalizedNote,
      source: 'portfolio_dividend',
      syncStatus: 'pending',
      transactionDate: DateTimeUtils.normalizeUtc(receivedDate),
      createdAt: now,
      updatedAt: now,
    );
    final Dividend dividend = Dividend(
      uuid: IdGenerator.newUuid(),
      symbol: normalizedSymbol,
      companyName: normalizedCompanyName,
      grossAmount: normalizedGrossAmount,
      tax: tax,
      netAmount: netAmount,
      receivedDate: DateTimeUtils.normalizeUtc(receivedDate),
      linkedTransactionUuid: moneyTransaction.uuid,
      note: normalizedNote,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.categorys.put(dividendCategory);
      await _isar.moneyTransactions.put(moneyTransaction);
      await _isar.dividends.put(dividend);
    });

    return DividendWithIncomeResult(
      dividend: dividend,
      incomeTransaction: moneyTransaction,
    );
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
    dividend.syncStatus = 'pending';
    dividend.syncErrorMessage = null;
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
        .thenByUpdatedAtDesc()
        .findAll();
  }

  Future<StockTransaction?> getStockTransactionByUuid(String uuid) {
    return _isar.stockTransactions.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<List<StockTransaction>> getActiveStockTransactionsBySymbol(
    String symbol,
  ) {
    final String normalizedSymbol = symbol.trim().toUpperCase();
    return _isar.stockTransactions
        .filter()
        .symbolEqualTo(normalizedSymbol)
        .and()
        .isDeletedEqualTo(false)
        .sortByTransactionDateDesc()
        .thenByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Dividend>> getActiveDividends() {
    return _isar.dividends
        .filter()
        .isDeletedEqualTo(false)
        .sortByReceivedDateDesc()
        .findAll();
  }

  Future<PortfolioOverview> getPortfolioOverview({
    int recentTransactionLimit = 10,
  }) async {
    final List<StockTransaction> transactions =
        await getActiveStockTransactions();
    final List<Dividend> dividends = await getActiveDividends();
    final List<PortfolioPositionSummary> positions = calculatePortfolioSummary(
      transactions,
    );
    final double totalModal = positions.fold<double>(
      0,
      (double value, PortfolioPositionSummary item) => value + item.totalCost,
    );
    final double totalDividen = dividends.fold<double>(
      0,
      (double value, Dividend item) => value + item.netAmount,
    );

    return PortfolioOverview(
      totalOwnedStocks: positions.where((item) => item.totalShares > 0).length,
      totalModal: totalModal,
      totalDividen: totalDividen,
      positions: positions,
      recentTransactions: transactions.take(recentTransactionLimit).toList(),
      dividends: dividends,
    );
  }

  List<PortfolioPositionSummary> calculatePortfolioSummary(
    List<StockTransaction> transactions,
  ) {
    final List<StockTransaction> sortedTransactions =
        <StockTransaction>[...transactions]
          ..sort((StockTransaction a, StockTransaction b) {
            final int transactionDateComparison = a.transactionDate.compareTo(
              b.transactionDate,
            );
            if (transactionDateComparison != 0) {
              return transactionDateComparison;
            }
            return a.createdAt.compareTo(b.createdAt);
          });

    final Map<String, _PortfolioAccumulator> positions =
        <String, _PortfolioAccumulator>{};

    for (final StockTransaction transaction in sortedTransactions) {
      final String symbol = transaction.symbol.trim().toUpperCase();
      final _PortfolioAccumulator accumulator = positions.putIfAbsent(
        symbol,
        _PortfolioAccumulator.new,
      );
      accumulator.symbol = symbol;
      if ((transaction.companyName ?? '').trim().isNotEmpty) {
        accumulator.companyName = transaction.companyName!.trim();
      }

      if (transaction.actionType == 'buy') {
        accumulator.totalShares += transaction.shares;
        accumulator.totalCost +=
            (transaction.shares * transaction.price) + transaction.fee;
        continue;
      }

      final int soldShares = transaction.shares > accumulator.totalShares
          ? accumulator.totalShares
          : transaction.shares;
      if (soldShares <= 0) {
        continue;
      }

      final double averageBeforeSell = accumulator.totalShares <= 0
          ? 0
          : accumulator.totalCost / accumulator.totalShares;
      accumulator.realizedProfit +=
          (soldShares * transaction.price) -
          transaction.fee -
          (averageBeforeSell * soldShares);
      accumulator.totalShares -= soldShares;
      accumulator.totalCost -= averageBeforeSell * soldShares;

      if (accumulator.totalShares <= 0) {
        accumulator.totalShares = 0;
        accumulator.totalCost = 0;
      }
    }

    final List<PortfolioPositionSummary> summaries =
        positions.values
            .map((item) => item.toSummary())
            .where((PortfolioPositionSummary item) => item.totalShares > 0)
            .toList(growable: false)
          ..sort(
            (PortfolioPositionSummary a, PortfolioPositionSummary b) =>
                b.totalCost.compareTo(a.totalCost),
          );

    return summaries;
  }

  Future<List<WatchlistItem>> getWatchlist() {
    return _isar.watchlistItems
        .filter()
        .isDeletedEqualTo(false)
        .sortBySymbol()
        .thenByUpdatedAtDesc()
        .findAll();
  }

  Future<WatchlistItem?> getWatchlistItemByUuid(String uuid) {
    return _isar.watchlistItems.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<WatchlistItem?> getActiveWatchlistItemBySymbol(String symbol) {
    final String normalizedSymbol = _normalizeSymbol(symbol);
    return _isar.watchlistItems
        .filter()
        .symbolEqualTo(normalizedSymbol)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  Future<WatchlistItem> createWatchlistItem({
    required String symbol,
    String? companyName,
    String market = 'IDX',
    double? targetPrice,
    String? note,
  }) async {
    final DateTime now = DateTimeUtils.utcNow();
    final String normalizedMarket = _normalizeMarket(market);
    final String normalizedSymbol = _normalizeSymbol(
      symbol,
      market: normalizedMarket,
    );
    final WatchlistItem? existing = await _isar.watchlistItems
        .filter()
        .symbolEqualTo(normalizedSymbol)
        .findFirst();

    if (existing != null) {
      existing.symbol = normalizedSymbol;
      existing.companyName = _normalizeNullable(companyName);
      existing.market = normalizedMarket;
      existing.targetPrice = targetPrice;
      existing.note = _normalizeNullable(note);
      existing.isDeleted = false;
      existing.deletedAt = null;
      existing.updatedAt = now;
      existing.createdAt = DateTimeUtils.normalizeUtc(existing.createdAt);
      existing.syncStatus = 'pending';
      existing.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.watchlistItems.put(existing);
      });
      return existing;
    }

    final WatchlistItem item = WatchlistItem(
      uuid: IdGenerator.newUuid(),
      symbol: normalizedSymbol,
      companyName: _normalizeNullable(companyName),
      market: normalizedMarket,
      targetPrice: targetPrice,
      note: _normalizeNullable(note),
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.watchlistItems.put(item);
    });

    return item;
  }

  Future<WatchlistItem> updateWatchlistItem(
    String uuid, {
    required String symbol,
    String? companyName,
    String market = 'IDX',
    double? targetPrice,
    String? note,
  }) async {
    final WatchlistItem? item = await getWatchlistItemByUuid(uuid);
    if (item == null || item.isDeleted) {
      throw StateError('Watchlist tidak ditemukan atau sudah dihapus.');
    }

    item.market = _normalizeMarket(market);
    item.symbol = _normalizeSymbol(symbol, market: item.market);
    item.companyName = _normalizeNullable(companyName);
    item.targetPrice = targetPrice;
    item.note = _normalizeNullable(note);
    item.updatedAt = DateTimeUtils.utcNow();
    item.deletedAt = null;
    item.isDeleted = false;
    item.syncStatus = 'pending';
    item.syncErrorMessage = null;

    await _isar.writeTxn(() async {
      await _isar.watchlistItems.put(item);
    });

    return item;
  }

  Future<List<WatchlistItem>> getWatchlistBySymbols(List<String> symbols) {
    final List<String> normalizedSymbols = symbols
        .map((String symbol) => _normalizeSymbol(symbol))
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedSymbols.isEmpty) {
      return Future<List<WatchlistItem>>.value(const <WatchlistItem>[]);
    }

    return _isar.watchlistItems
        .filter()
        .anyOf(
          normalizedSymbols,
          (q, String symbol) =>
              q.symbolEqualTo(symbol).and().isDeletedEqualTo(false),
        )
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<WatchlistItem> upsertWatchlistItem(WatchlistItem item) async {
    final DateTime now = DateTimeUtils.utcNow();
    item.market = _normalizeMarket(item.market);
    item.symbol = _normalizeSymbol(item.symbol, market: item.market);
    item.companyName = _normalizeNullable(item.companyName);
    item.note = _normalizeNullable(item.note);
    item.createdAt = DateTimeUtils.normalizeUtc(item.createdAt);
    item.updatedAt = now;
    item.syncStatus = 'pending';
    item.syncErrorMessage = null;
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
    item.syncStatus = 'pending';
    item.syncErrorMessage = null;

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

  String _normalizeMarket(String value) {
    final String normalized = value.trim().toUpperCase();
    return normalized.isEmpty ? 'IDX' : normalized;
  }

  String _normalizeSymbol(String value, {String market = 'IDX'}) {
    final String normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      return '';
    }
    if (_normalizeMarket(market) == 'IDX' && normalized.endsWith('.JK')) {
      return normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }

  String _normalizeActionType(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized != 'buy' && normalized != 'sell') {
      throw StateError('Tipe aksi saham hanya boleh buy atau sell.');
    }
    return normalized;
  }

  Future<Category> _resolveDividendCategory() async {
    final Category? existingByName = await _isar.categorys
        .filter()
        .nameEqualTo('Dividen', caseSensitive: false)
        .and()
        .typeEqualTo('income')
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
    if (existingByName != null) {
      return existingByName;
    }

    final Category? existingByUuid = await _isar.categorys
        .filter()
        .uuidEqualTo(CategoryRepository.defaultDividendCategoryUuid)
        .findFirst();
    if (existingByUuid != null) {
      existingByUuid.isDeleted = false;
      existingByUuid.updatedAt = DateTimeUtils.utcNow();
      existingByUuid.deletedAt = null;
      existingByUuid.syncStatus = 'pending';
      existingByUuid.syncErrorMessage = null;
      existingByUuid.type = 'income';
      existingByUuid.name = 'Dividen';
      return existingByUuid;
    }

    final DateTime now = DateTimeUtils.utcNow();
    return Category(
      uuid: CategoryRepository.defaultDividendCategoryUuid,
      name: 'Dividen',
      type: 'income',
      iconName: 'landmark',
      colorHex: '#3B82F6',
      isDefault: true,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    );
  }
}

class PortfolioOverview {
  const PortfolioOverview({
    required this.totalOwnedStocks,
    required this.totalModal,
    required this.totalDividen,
    required this.positions,
    required this.recentTransactions,
    required this.dividends,
  });

  final int totalOwnedStocks;
  final double totalModal;
  final double totalDividen;
  final List<PortfolioPositionSummary> positions;
  final List<StockTransaction> recentTransactions;
  final List<Dividend> dividends;
}

class PortfolioPositionSummary {
  const PortfolioPositionSummary({
    required this.symbol,
    required this.companyName,
    required this.totalLot,
    required this.totalShares,
    required this.averageBuyPrice,
    required this.totalCost,
    required this.realizedProfit,
  });

  final String symbol;
  final String? companyName;
  final double totalLot;
  final int totalShares;
  final double averageBuyPrice;
  final double totalCost;
  final double realizedProfit;
}

class DividendWithIncomeResult {
  const DividendWithIncomeResult({
    required this.dividend,
    required this.incomeTransaction,
  });

  final Dividend dividend;
  final MoneyTransaction incomeTransaction;
}

class _PortfolioAccumulator {
  String symbol = '';
  String? companyName;
  int totalShares = 0;
  double totalCost = 0;
  double realizedProfit = 0;

  PortfolioPositionSummary toSummary() {
    final double normalizedCost = totalCost < 0 ? 0 : totalCost;
    return PortfolioPositionSummary(
      symbol: symbol,
      companyName: companyName,
      totalLot: totalShares / 100,
      totalShares: totalShares,
      averageBuyPrice: totalShares == 0 ? 0 : normalizedCost / totalShares,
      totalCost: normalizedCost,
      realizedProfit: realizedProfit,
    );
  }
}
