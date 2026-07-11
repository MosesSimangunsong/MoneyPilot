import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import '../../core/constants/sheet_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/sync_log.dart';
import '../models/watchlist_item.dart';
import '../services/spreadsheet_sync_mapper.dart';
import '../services/spreadsheet_sync_service.dart';
import 'app_setting_repository.dart';

class SyncRepository {
  SyncRepository(
    this._isar, {
    required AppSettingRepository appSettingRepository,
    required SpreadsheetSyncService spreadsheetSyncService,
  }) : _appSettingRepository = appSettingRepository,
       _spreadsheetSyncService = spreadsheetSyncService;

  final Isar _isar;
  final AppSettingRepository _appSettingRepository;
  final SpreadsheetSyncService _spreadsheetSyncService;

  Future<int> countPendingSyncItems() async {
    final int pendingCategories = await _countPendingCollection<Category>(
      _isar.categorys.filter().group(
        (q) => q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
      ),
    );
    final int pendingTransactions =
        await _countPendingCollection<MoneyTransaction>(
          _isar.moneyTransactions.filter().group(
            (q) =>
                q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
          ),
        );
    final int pendingStockTransactions =
        await _countPendingCollection<StockTransaction>(
          _isar.stockTransactions.filter().group(
            (q) =>
                q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
          ),
        );
    final int pendingDividends = await _countPendingCollection<Dividend>(
      _isar.dividends.filter().group(
        (q) => q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
      ),
    );
    final int pendingWatchlist = await _countPendingCollection<WatchlistItem>(
      _isar.watchlistItems.filter().group(
        (q) => q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
      ),
    );
    return pendingCategories +
        pendingTransactions +
        pendingStockTransactions +
        pendingDividends +
        pendingWatchlist;
  }

  Future<int> countUnsyncedItems() => countPendingSyncItems();

  Future<SyncRunSummary> syncAll() async {
    final settings = await _appSettingRepository.getOrCreateSettings();
    final String webAppUrl = settings.gasWebhookUrl?.trim() ?? '';
    final String token = settings.gasSecretToken?.trim() ?? '';

    if (webAppUrl.isEmpty || token.isEmpty) {
      throw StateError(
        'URL Google Apps Script dan secret token wajib disimpan sebelum sync.',
      );
    }

    final DateTime startedAt = DateTimeUtils.utcNow();
    final List<Category> categoriesToPush = await _loadPendingCategories();
    final List<MoneyTransaction> transactionsToPush =
        await _loadPendingTransactions();
    final List<StockTransaction> stockTransactionsToPush =
        await _loadPendingStockTransactions();
    final List<Dividend> dividendsToPush = await _loadPendingDividends();
    final List<WatchlistItem> watchlistToPush = await _loadPendingWatchlist();

    DateTime? lastServerTime;
    String currentStage = 'persiapan sync';
    int pushedCategories = 0;
    int pushedTransactions = 0;
    int pushedStockTransactions = 0;
    int pushedDividends = 0;
    int pushedWatchlist = 0;
    int pulledCategories = 0;
    int pulledTransactions = 0;
    int pulledStockTransactions = 0;
    int pulledDividends = 0;
    int pulledWatchlist = 0;

    try {
      currentStage = 'push Categories';
      lastServerTime = await _pushEntityIfNeeded(
        stage: 'push Categories',
        webAppUrl: webAppUrl,
        token: token,
        entity: SheetConstants.categories,
        countItems: categoriesToPush.length,
        push: () => pushCategoriesIfNeeded(
          webAppUrl: webAppUrl,
          token: token,
          categories: categoriesToPush,
        ),
        onPushed: (int count) => pushedCategories = count,
        currentServerTime: lastServerTime,
      );

      currentStage = 'push Transactions';
      lastServerTime = await _pushEntityIfNeeded(
        stage: 'push Transactions',
        webAppUrl: webAppUrl,
        token: token,
        entity: SheetConstants.transactions,
        countItems: transactionsToPush.length,
        push: () => pushPendingTransactions(
          webAppUrl: webAppUrl,
          token: token,
          transactions: transactionsToPush,
        ),
        onPushed: (int count) => pushedTransactions = count,
        currentServerTime: lastServerTime,
      );

      currentStage = 'push Stock_Transactions';
      lastServerTime = await _pushEntityIfNeeded(
        stage: 'push Stock_Transactions',
        webAppUrl: webAppUrl,
        token: token,
        entity: SheetConstants.stockTransactions,
        countItems: stockTransactionsToPush.length,
        push: () => pushPendingStockTransactions(
          webAppUrl: webAppUrl,
          token: token,
          transactions: stockTransactionsToPush,
        ),
        onPushed: (int count) => pushedStockTransactions = count,
        currentServerTime: lastServerTime,
      );

      currentStage = 'push Dividends';
      lastServerTime = await _pushEntityIfNeeded(
        stage: 'push Dividends',
        webAppUrl: webAppUrl,
        token: token,
        entity: SheetConstants.dividends,
        countItems: dividendsToPush.length,
        push: () => pushPendingDividends(
          webAppUrl: webAppUrl,
          token: token,
          dividends: dividendsToPush,
        ),
        onPushed: (int count) => pushedDividends = count,
        currentServerTime: lastServerTime,
      );

      currentStage = 'push Watchlist';
      lastServerTime = await _pushEntityIfNeeded(
        stage: 'push Watchlist',
        webAppUrl: webAppUrl,
        token: token,
        entity: SheetConstants.watchlist,
        countItems: watchlistToPush.length,
        push: () => pushPendingWatchlist(
          webAppUrl: webAppUrl,
          token: token,
          watchlist: watchlistToPush,
        ),
        onPushed: (int count) => pushedWatchlist = count,
        currentServerTime: lastServerTime,
      );

      currentStage = 'pull Categories';
      final SpreadsheetSyncResponse pullCategoriesResponse =
          await pullCategories(
            webAppUrl: webAppUrl,
            token: token,
            since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
          );
      pulledCategories = await _mergeCategories(pullCategoriesResponse.items);
      lastServerTime = pullCategoriesResponse.serverTime ?? lastServerTime;

      currentStage = 'pull Transactions';
      final SpreadsheetSyncResponse pullTransactionsResponse =
          await pullTransactions(
            webAppUrl: webAppUrl,
            token: token,
            since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
          );
      pulledTransactions = await _mergeTransactions(
        pullTransactionsResponse.items,
      );
      lastServerTime = pullTransactionsResponse.serverTime ?? lastServerTime;

      currentStage = 'pull Stock_Transactions';
      final SpreadsheetSyncResponse pullStockTransactionsResponse =
          await pullStockTransactions(
            webAppUrl: webAppUrl,
            token: token,
            since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
          );
      pulledStockTransactions = await _mergeStockTransactions(
        pullStockTransactionsResponse.items,
      );
      lastServerTime =
          pullStockTransactionsResponse.serverTime ?? lastServerTime;

      currentStage = 'pull Dividends';
      final SpreadsheetSyncResponse pullDividendsResponse = await pullDividends(
        webAppUrl: webAppUrl,
        token: token,
        since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
      );
      pulledDividends = await _mergeDividends(pullDividendsResponse.items);
      lastServerTime = pullDividendsResponse.serverTime ?? lastServerTime;

      currentStage = 'pull Watchlist';
      final SpreadsheetSyncResponse pullWatchlistResponse = await pullWatchlist(
        webAppUrl: webAppUrl,
        token: token,
        since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
      );
      pulledWatchlist = await _mergeWatchlist(pullWatchlistResponse.items);
      lastServerTime = pullWatchlistResponse.serverTime ?? lastServerTime;

      final DateTime completedAt = lastServerTime ?? DateTimeUtils.utcNow();
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: completedAt,
        lastSpreadsheetPullAt: completedAt,
        status: 'synced',
        message: 'Sinkronisasi spreadsheet berhasil.',
      );
      await _writeSyncLog(
        entityType: 'spreadsheet',
        action: 'sync_all',
        status: 'success',
        syncedAt: completedAt,
      );

      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: completedAt,
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pushedWatchlist: pushedWatchlist,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        pulledWatchlist: pulledWatchlist,
        pendingCount: await countPendingSyncItems(),
        status: 'success',
        message: 'Sinkronisasi spreadsheet berhasil.',
      );
    } on SpreadsheetSyncException catch (error) {
      final String message = _buildStageFailureMessage(
        currentStage: currentStage,
        baseMessage: error.message,
      );
      await _markPushFailure(
        categories: categoriesToPush,
        transactions: transactionsToPush,
        stockTransactions: stockTransactionsToPush,
        dividends: dividendsToPush,
        watchlist: watchlistToPush,
        message: message,
      );
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: DateTimeUtils.utcNow(),
        status: 'failed',
        message: message,
      );
      await _writeSyncLog(
        entityType: 'spreadsheet',
        action: 'sync_all',
        status: 'failed',
        errorMessage: message,
      );
      _logStageFailure(currentStage, message);
      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: DateTimeUtils.utcNow(),
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pushedWatchlist: pushedWatchlist,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        pulledWatchlist: pulledWatchlist,
        pendingCount: await countPendingSyncItems(),
        status: 'failed',
        message: message,
      );
    } on FormatException catch (error) {
      final String message = _buildStageFailureMessage(
        currentStage: currentStage,
        baseMessage: error.message,
      );
      await _markPushFailure(
        categories: categoriesToPush,
        transactions: transactionsToPush,
        stockTransactions: stockTransactionsToPush,
        dividends: dividendsToPush,
        watchlist: watchlistToPush,
        message: message,
      );
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: DateTimeUtils.utcNow(),
        status: 'failed',
        message: message,
      );
      await _writeSyncLog(
        entityType: 'spreadsheet',
        action: 'sync_all',
        status: 'failed',
        errorMessage: message,
      );
      _logStageFailure(currentStage, message);
      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: DateTimeUtils.utcNow(),
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pushedWatchlist: pushedWatchlist,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        pulledWatchlist: pulledWatchlist,
        pendingCount: await countPendingSyncItems(),
        status: 'failed',
        message: message,
      );
    }
  }

  Future<SyncRunSummary> syncNow() => syncAll();

  Future<SpreadsheetSyncResponse?> pushCategoriesIfNeeded({
    required String webAppUrl,
    required String token,
    List<Category>? categories,
  }) async {
    final List<Category> items = categories ?? await _loadPendingCategories();
    if (items.isEmpty) {
      return null;
    }

    _logStageStart('push Categories', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.push(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.categories,
      items: items
          .map(SpreadsheetSyncMapper.categoryToPayload)
          .toList(growable: false),
    );
    await _markCategoriesSynced(items);
    _logStageSuccess('push Categories', response);
    return response;
  }

  Future<SpreadsheetSyncResponse?> pushPendingTransactions({
    required String webAppUrl,
    required String token,
    List<MoneyTransaction>? transactions,
  }) async {
    final List<MoneyTransaction> items =
        transactions ?? await _loadPendingTransactions();
    if (items.isEmpty) {
      return null;
    }

    _logStageStart('push Transactions', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.push(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.transactions,
      items: items
          .map(SpreadsheetSyncMapper.transactionToPayload)
          .toList(growable: false),
    );
    await _markTransactionsSynced(items);
    _logStageSuccess('push Transactions', response);
    return response;
  }

  Future<SpreadsheetSyncResponse?> pushPendingStockTransactions({
    required String webAppUrl,
    required String token,
    List<StockTransaction>? transactions,
  }) async {
    final List<StockTransaction> items =
        transactions ?? await _loadPendingStockTransactions();
    if (items.isEmpty) {
      return null;
    }

    _logStageStart('push Stock_Transactions', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.push(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.stockTransactions,
      items: items
          .map(SpreadsheetSyncMapper.stockTransactionToPayload)
          .toList(growable: false),
    );
    await _markStockTransactionsSynced(items);
    _logStageSuccess('push Stock_Transactions', response);
    return response;
  }

  Future<SpreadsheetSyncResponse?> pushPendingDividends({
    required String webAppUrl,
    required String token,
    List<Dividend>? dividends,
  }) async {
    final List<Dividend> items = dividends ?? await _loadPendingDividends();
    if (items.isEmpty) {
      return null;
    }

    _logStageStart('push Dividends', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.push(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.dividends,
      items: items
          .map(SpreadsheetSyncMapper.dividendToPayload)
          .toList(growable: false),
    );
    await _markDividendsSynced(items);
    _logStageSuccess('push Dividends', response);
    return response;
  }

  Future<SpreadsheetSyncResponse?> pushPendingWatchlist({
    required String webAppUrl,
    required String token,
    List<WatchlistItem>? watchlist,
  }) async {
    final List<WatchlistItem> items =
        watchlist ?? await _loadPendingWatchlist();
    if (items.isEmpty) {
      return null;
    }

    _logStageStart('push Watchlist', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.push(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.watchlist,
      items: items
          .map(SpreadsheetSyncMapper.watchlistToPayload)
          .toList(growable: false),
    );
    await _markWatchlistSynced(items);
    _logStageSuccess('push Watchlist', response);
    return response;
  }

  Future<SpreadsheetSyncResponse> pullCategories({
    required String webAppUrl,
    required String token,
    String? since,
  }) async {
    _logStageStart('pull Categories', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.pull(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.categories,
      since: since,
    );
    _logStageSuccess('pull Categories', response);
    return response;
  }

  Future<SpreadsheetSyncResponse> pullTransactions({
    required String webAppUrl,
    required String token,
    String? since,
  }) async {
    _logStageStart('pull Transactions', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.pull(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.transactions,
      since: since,
    );
    _logStageSuccess('pull Transactions', response);
    return response;
  }

  Future<SpreadsheetSyncResponse> pullStockTransactions({
    required String webAppUrl,
    required String token,
    String? since,
  }) async {
    _logStageStart('pull Stock_Transactions', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.pull(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.stockTransactions,
      since: since,
    );
    _logStageSuccess('pull Stock_Transactions', response);
    return response;
  }

  Future<SpreadsheetSyncResponse> pullDividends({
    required String webAppUrl,
    required String token,
    String? since,
  }) async {
    _logStageStart('pull Dividends', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.pull(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.dividends,
      since: since,
    );
    _logStageSuccess('pull Dividends', response);
    return response;
  }

  Future<SpreadsheetSyncResponse> pullWatchlist({
    required String webAppUrl,
    required String token,
    String? since,
  }) async {
    _logStageStart('pull Watchlist', webAppUrl);
    final SpreadsheetSyncResponse response = await _spreadsheetSyncService.pull(
      webAppUrl: webAppUrl,
      token: token,
      entity: SheetConstants.watchlist,
      since: since,
    );
    _logStageSuccess('pull Watchlist', response);
    return response;
  }

  Future<int> _countPendingCollection<T>(
    QueryBuilder<T, T, QAfterFilterCondition> query,
  ) {
    return query.count();
  }

  Future<DateTime?> _pushEntityIfNeeded({
    required String stage,
    required String webAppUrl,
    required String token,
    required String entity,
    required int countItems,
    required Future<SpreadsheetSyncResponse?> Function() push,
    required void Function(int count) onPushed,
    required DateTime? currentServerTime,
  }) async {
    if (countItems == 0) {
      return currentServerTime;
    }
    final SpreadsheetSyncResponse? response = await push();
    if (response == null) {
      return currentServerTime;
    }
    onPushed(countItems);
    return response.serverTime ?? currentServerTime;
  }

  Future<List<Category>> _loadPendingCategories() {
    return _isar.categorys
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
  }

  Future<List<MoneyTransaction>> _loadPendingTransactions() {
    return _isar.moneyTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
  }

  Future<List<StockTransaction>> _loadPendingStockTransactions() {
    return _isar.stockTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
  }

  Future<List<Dividend>> _loadPendingDividends() {
    return _isar.dividends
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
  }

  Future<List<WatchlistItem>> _loadPendingWatchlist() {
    return _isar.watchlistItems
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
  }

  Future<int> _mergeCategories(List<Map<String, dynamic>> payloads) async {
    int changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final Category remote = SpreadsheetSyncMapper.categoryFromPayload(
        payload,
      );
      final Category? local = await _isar.categorys
          .filter()
          .uuidEqualTo(remote.uuid)
          .findFirst();

      if (local == null) {
        remote.syncStatus = 'synced';
        remote.syncErrorMessage = null;
        await _isar.writeTxn(() async {
          await _isar.categorys.put(remote);
        });
        changed++;
        continue;
      }

      if (!_isRemoteNewer(local.updatedAt, remote.updatedAt)) {
        continue;
      }

      remote.id = local.id;
      remote.syncStatus = 'synced';
      remote.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.categorys.put(remote);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeTransactions(List<Map<String, dynamic>> payloads) async {
    int changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final MoneyTransaction remote =
          SpreadsheetSyncMapper.transactionFromPayload(payload);
      final MoneyTransaction? local = await _isar.moneyTransactions
          .filter()
          .uuidEqualTo(remote.uuid)
          .findFirst();

      if (local == null) {
        remote.syncStatus = 'synced';
        remote.syncErrorMessage = null;
        await _isar.writeTxn(() async {
          await _isar.moneyTransactions.put(remote);
        });
        changed++;
        continue;
      }

      if (!_isRemoteNewer(local.updatedAt, remote.updatedAt)) {
        continue;
      }

      if (remote.isDeleted) {
        local.isDeleted = true;
        local.deletedAt = remote.deletedAt ?? remote.updatedAt;
      } else {
        local.isDeleted = false;
        local.deletedAt = null;
      }
      local.type = remote.type;
      local.title = remote.title;
      local.amount = remote.amount;
      local.categoryUuid = remote.categoryUuid;
      local.categoryNameSnapshot = remote.categoryNameSnapshot;
      local.paymentMethod = remote.paymentMethod;
      local.note = remote.note;
      local.source = remote.source;
      local.transactionDate = remote.transactionDate;
      local.createdAt = remote.createdAt;
      local.updatedAt = remote.updatedAt;
      local.syncStatus = 'synced';
      local.syncErrorMessage = null;

      await _isar.writeTxn(() async {
        await _isar.moneyTransactions.put(local);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeStockTransactions(
    List<Map<String, dynamic>> payloads,
  ) async {
    int changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final StockTransaction remote =
          SpreadsheetSyncMapper.stockTransactionFromPayload(payload);
      final StockTransaction? local = await _isar.stockTransactions
          .filter()
          .uuidEqualTo(remote.uuid)
          .findFirst();

      if (local == null) {
        remote.syncStatus = 'synced';
        remote.syncErrorMessage = null;
        await _isar.writeTxn(() async {
          await _isar.stockTransactions.put(remote);
        });
        changed++;
        continue;
      }

      if (!_isRemoteNewer(local.updatedAt, remote.updatedAt)) {
        continue;
      }

      local.symbol = remote.symbol.trim().toUpperCase();
      local.companyName = remote.companyName;
      local.actionType = remote.actionType;
      local.lot = remote.lot;
      local.shares = remote.shares;
      local.price = remote.price;
      local.fee = remote.fee;
      local.transactionDate = remote.transactionDate;
      local.note = remote.note;
      local.createdAt = remote.createdAt;
      local.updatedAt = remote.updatedAt;
      local.isDeleted = remote.isDeleted;
      local.deletedAt = remote.isDeleted ? remote.deletedAt : null;
      local.syncStatus = 'synced';
      local.syncErrorMessage = null;

      await _isar.writeTxn(() async {
        await _isar.stockTransactions.put(local);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeDividends(List<Map<String, dynamic>> payloads) async {
    int changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final Dividend remote = SpreadsheetSyncMapper.dividendFromPayload(
        payload,
      );
      final Dividend? local = await _isar.dividends
          .filter()
          .uuidEqualTo(remote.uuid)
          .findFirst();

      if (local == null) {
        remote.syncStatus = 'synced';
        remote.syncErrorMessage = null;
        await _isar.writeTxn(() async {
          await _isar.dividends.put(remote);
        });
        changed++;
        continue;
      }

      if (!_isRemoteNewer(local.updatedAt, remote.updatedAt)) {
        continue;
      }

      local.symbol = remote.symbol.trim().toUpperCase();
      local.companyName = remote.companyName;
      local.grossAmount = remote.grossAmount;
      local.tax = remote.tax;
      local.netAmount = remote.netAmount;
      local.receivedDate = remote.receivedDate;
      local.linkedTransactionUuid = remote.linkedTransactionUuid;
      local.note = remote.note;
      local.createdAt = remote.createdAt;
      local.updatedAt = remote.updatedAt;
      local.isDeleted = remote.isDeleted;
      local.deletedAt = remote.isDeleted ? remote.deletedAt : null;
      local.syncStatus = 'synced';
      local.syncErrorMessage = null;

      await _isar.writeTxn(() async {
        await _isar.dividends.put(local);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeWatchlist(List<Map<String, dynamic>> payloads) async {
    int changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final WatchlistItem remote = SpreadsheetSyncMapper.watchlistFromPayload(
        payload,
      );
      final String normalizedSymbol = _normalizeWatchlistSymbol(
        remote.symbol,
        remote.market,
      );
      remote.symbol = normalizedSymbol;

      WatchlistItem? local = await _isar.watchlistItems
          .filter()
          .uuidEqualTo(remote.uuid)
          .findFirst();

      local ??= await _isar.watchlistItems
          .filter()
          .symbolEqualTo(normalizedSymbol)
          .and()
          .marketEqualTo(remote.market, caseSensitive: false)
          .findFirst();

      if (local == null) {
        remote.syncStatus = 'synced';
        remote.syncErrorMessage = null;
        await _isar.writeTxn(() async {
          await _isar.watchlistItems.put(remote);
        });
        changed++;
        continue;
      }

      if (!_isRemoteNewer(local.updatedAt, remote.updatedAt)) {
        continue;
      }

      remote.id = local.id;
      remote.syncStatus = 'synced';
      remote.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.watchlistItems.put(remote);
      });
      changed++;
    }

    return changed;
  }

  bool _isRemoteNewer(DateTime localUpdatedAt, DateTime remoteUpdatedAt) {
    return DateTimeUtils.normalizeUtc(
      remoteUpdatedAt,
    ).isAfter(DateTimeUtils.normalizeUtc(localUpdatedAt));
  }

  String _normalizeWatchlistSymbol(String value, String market) {
    final String normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      return normalized;
    }
    if (market.trim().toUpperCase() == 'IDX' && normalized.endsWith('.JK')) {
      return normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }

  Future<void> _markCategoriesSynced(List<Category> items) async {
    if (items.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final Category item in items) {
        item.syncStatus = 'synced';
        item.syncErrorMessage = null;
      }
      await _isar.categorys.putAll(items);
    });
  }

  Future<void> _markTransactionsSynced(List<MoneyTransaction> items) async {
    if (items.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final MoneyTransaction item in items) {
        item.syncStatus = 'synced';
        item.syncErrorMessage = null;
      }
      await _isar.moneyTransactions.putAll(items);
    });
  }

  Future<void> _markStockTransactionsSynced(
    List<StockTransaction> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final StockTransaction item in items) {
        item.syncStatus = 'synced';
        item.syncErrorMessage = null;
      }
      await _isar.stockTransactions.putAll(items);
    });
  }

  Future<void> _markDividendsSynced(List<Dividend> items) async {
    if (items.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final Dividend item in items) {
        item.syncStatus = 'synced';
        item.syncErrorMessage = null;
      }
      await _isar.dividends.putAll(items);
    });
  }

  Future<void> _markWatchlistSynced(List<WatchlistItem> items) async {
    if (items.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final WatchlistItem item in items) {
        item.syncStatus = 'synced';
        item.syncErrorMessage = null;
      }
      await _isar.watchlistItems.putAll(items);
    });
  }

  Future<void> _markPushFailure({
    required List<Category> categories,
    required List<MoneyTransaction> transactions,
    required List<StockTransaction> stockTransactions,
    required List<Dividend> dividends,
    required List<WatchlistItem> watchlist,
    required String message,
  }) async {
    await _isar.writeTxn(() async {
      for (final Category item in categories) {
        if (item.syncStatus != 'synced') {
          item.syncStatus = 'failed';
          item.syncErrorMessage = message;
        }
      }
      if (categories.isNotEmpty) {
        await _isar.categorys.putAll(categories);
      }

      for (final MoneyTransaction item in transactions) {
        if (item.syncStatus != 'synced') {
          item.syncStatus = 'failed';
          item.syncErrorMessage = message;
        }
      }
      if (transactions.isNotEmpty) {
        await _isar.moneyTransactions.putAll(transactions);
      }

      for (final StockTransaction item in stockTransactions) {
        if (item.syncStatus != 'synced') {
          item.syncStatus = 'failed';
          item.syncErrorMessage = message;
        }
      }
      if (stockTransactions.isNotEmpty) {
        await _isar.stockTransactions.putAll(stockTransactions);
      }

      for (final Dividend item in dividends) {
        if (item.syncStatus != 'synced') {
          item.syncStatus = 'failed';
          item.syncErrorMessage = message;
        }
      }
      if (dividends.isNotEmpty) {
        await _isar.dividends.putAll(dividends);
      }

      for (final WatchlistItem item in watchlist) {
        if (item.syncStatus != 'synced') {
          item.syncStatus = 'failed';
          item.syncErrorMessage = message;
        }
      }
      if (watchlist.isNotEmpty) {
        await _isar.watchlistItems.putAll(watchlist);
      }
    });
  }

  Future<void> _writeSyncLog({
    required String entityType,
    required String action,
    required String status,
    DateTime? syncedAt,
    String? errorMessage,
  }) async {
    final DateTime now = DateTimeUtils.utcNow();
    final SyncLog log = SyncLog(
      uuid: IdGenerator.newUuid(),
      entityType: entityType,
      entityUuid: entityType,
      action: action,
      status: status,
      errorMessage: errorMessage,
      createdAt: now,
      syncedAt: syncedAt ?? now,
    );

    await _isar.writeTxn(() async {
      await _isar.syncLogs.put(log);
    });
  }

  String _buildStageFailureMessage({
    required String currentStage,
    required String baseMessage,
  }) {
    final String normalizedStage = currentStage.trim().isEmpty
        ? 'sync'
        : currentStage.trim();
    return 'Gagal pada tahap $normalizedStage. $baseMessage';
  }

  void _logStageStart(String stage, String url) {
    developer.log(
      'Mulai tahap $stage menggunakan url=$url',
      name: 'SyncRepository',
    );
  }

  void _logStageSuccess(String stage, SpreadsheetSyncResponse response) {
    developer.log(
      'Tahap $stage berhasil. inserted=${response.inserted} updated=${response.updated} failed=${response.failed}',
      name: 'SyncRepository',
    );
  }

  void _logStageFailure(String stage, String message) {
    developer.log(
      'Tahap $stage gagal. $message',
      name: 'SyncRepository',
      level: 1000,
    );
  }
}

class SyncRunSummary {
  const SyncRunSummary({
    required this.startedAt,
    required this.completedAt,
    required this.pushedCategories,
    required this.pushedTransactions,
    required this.pushedStockTransactions,
    required this.pushedDividends,
    required this.pushedWatchlist,
    required this.pulledCategories,
    required this.pulledTransactions,
    required this.pulledStockTransactions,
    required this.pulledDividends,
    required this.pulledWatchlist,
    required this.pendingCount,
    required this.status,
    required this.message,
  });

  final DateTime startedAt;
  final DateTime completedAt;
  final int pushedCategories;
  final int pushedTransactions;
  final int pushedStockTransactions;
  final int pushedDividends;
  final int pushedWatchlist;
  final int pulledCategories;
  final int pulledTransactions;
  final int pulledStockTransactions;
  final int pulledDividends;
  final int pulledWatchlist;
  final int pendingCount;
  final String status;
  final String message;
}
