import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import '../../core/constants/sheet_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/app_setting.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/sync_log.dart';
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

  Future<int> countUnsyncedItems() async {
    final int pendingCategories = await _isar.categorys
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .count();
    final int pendingTransactions = await _isar.moneyTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .count();
    final int pendingStockTransactions = await _isar.stockTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .count();
    final int pendingDividends = await _isar.dividends
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .count();
    return pendingCategories +
        pendingTransactions +
        pendingStockTransactions +
        pendingDividends;
  }

  Future<SyncRunSummary> syncNow() async {
    final AppSetting settings = await _appSettingRepository
        .getOrCreateSettings();
    final String webAppUrl = settings.gasWebhookUrl?.trim() ?? '';
    final String token = settings.gasSecretToken?.trim() ?? '';

    if (webAppUrl.isEmpty || token.isEmpty) {
      throw StateError(
        'URL Google Apps Script dan secret token wajib disimpan sebelum sync.',
      );
    }

    final DateTime startedAt = DateTimeUtils.utcNow();
    final List<Category> categoriesToPush = await _isar.categorys
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
    final List<MoneyTransaction> transactionsToPush = await _isar
        .moneyTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
    final List<StockTransaction> stockTransactionsToPush = await _isar
        .stockTransactions
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();
    final List<Dividend> dividendsToPush = await _isar.dividends
        .filter()
        .group(
          (q) =>
              q.syncStatusEqualTo('pending').or().syncStatusEqualTo('failed'),
        )
        .sortByUpdatedAt()
        .findAll();

    DateTime? lastServerTime;
    var pushedCategories = 0;
    var pushedTransactions = 0;
    var pushedStockTransactions = 0;
    var pushedDividends = 0;
    var pulledCategories = 0;
    var pulledTransactions = 0;
    var pulledStockTransactions = 0;
    var pulledDividends = 0;
    var currentStage = 'load_settings';

    try {
      if (categoriesToPush.isNotEmpty) {
        currentStage = 'push Categories';
        _logStageStart(currentStage, webAppUrl);
        final SpreadsheetSyncResponse pushCategoriesResponse =
            await _spreadsheetSyncService.push(
              webAppUrl: webAppUrl,
              token: token,
              entity: SheetConstants.categories,
              items: categoriesToPush
                  .map(SpreadsheetSyncMapper.categoryToPayload)
                  .toList(growable: false),
            );
        lastServerTime = pushCategoriesResponse.serverTime ?? lastServerTime;
        pushedCategories = categoriesToPush.length;
        await _markCategoriesSynced(categoriesToPush);
        _logStageSuccess(currentStage, pushCategoriesResponse);
        await _writeSyncLog(
          entityType: SheetConstants.categories,
          action: 'push',
          status: 'success',
          syncedAt: lastServerTime,
        );
      }

      if (transactionsToPush.isNotEmpty) {
        currentStage = 'push Transactions';
        _logStageStart(currentStage, webAppUrl);
        final SpreadsheetSyncResponse pushTransactionsResponse =
            await _spreadsheetSyncService.push(
              webAppUrl: webAppUrl,
              token: token,
              entity: SheetConstants.transactions,
              items: transactionsToPush
                  .map(SpreadsheetSyncMapper.transactionToPayload)
                  .toList(growable: false),
            );
        lastServerTime = pushTransactionsResponse.serverTime ?? lastServerTime;
        pushedTransactions = transactionsToPush.length;
        await _markTransactionsSynced(transactionsToPush);
        _logStageSuccess(currentStage, pushTransactionsResponse);
        await _writeSyncLog(
          entityType: SheetConstants.transactions,
          action: 'push',
          status: 'success',
          syncedAt: lastServerTime,
        );
      }

      if (stockTransactionsToPush.isNotEmpty) {
        currentStage = 'push Stock_Transactions';
        _logStageStart(currentStage, webAppUrl);
        final SpreadsheetSyncResponse pushStockTransactionsResponse =
            await _spreadsheetSyncService.push(
              webAppUrl: webAppUrl,
              token: token,
              entity: SheetConstants.stockTransactions,
              items: stockTransactionsToPush
                  .map(SpreadsheetSyncMapper.stockTransactionToPayload)
                  .toList(growable: false),
            );
        lastServerTime =
            pushStockTransactionsResponse.serverTime ?? lastServerTime;
        pushedStockTransactions = stockTransactionsToPush.length;
        await _markStockTransactionsSynced(stockTransactionsToPush);
        _logStageSuccess(currentStage, pushStockTransactionsResponse);
        await _writeSyncLog(
          entityType: SheetConstants.stockTransactions,
          action: 'push',
          status: 'success',
          syncedAt: lastServerTime,
        );
      }

      if (dividendsToPush.isNotEmpty) {
        currentStage = 'push Dividends';
        _logStageStart(currentStage, webAppUrl);
        final SpreadsheetSyncResponse pushDividendsResponse =
            await _spreadsheetSyncService.push(
              webAppUrl: webAppUrl,
              token: token,
              entity: SheetConstants.dividends,
              items: dividendsToPush
                  .map(SpreadsheetSyncMapper.dividendToPayload)
                  .toList(growable: false),
            );
        lastServerTime = pushDividendsResponse.serverTime ?? lastServerTime;
        pushedDividends = dividendsToPush.length;
        await _markDividendsSynced(dividendsToPush);
        _logStageSuccess(currentStage, pushDividendsResponse);
        await _writeSyncLog(
          entityType: SheetConstants.dividends,
          action: 'push',
          status: 'success',
          syncedAt: lastServerTime,
        );
      }

      currentStage = 'pull Categories';
      _logStageStart(currentStage, webAppUrl);
      final SpreadsheetSyncResponse pullCategoriesResponse =
          await _spreadsheetSyncService.pull(
            webAppUrl: webAppUrl,
            token: token,
            entity: SheetConstants.categories,
            since: settings.lastSpreadsheetPullAt,
          );
      pulledCategories = await _mergeCategories(pullCategoriesResponse.items);
      lastServerTime = pullCategoriesResponse.serverTime ?? lastServerTime;
      _logStageSuccess(currentStage, pullCategoriesResponse);
      await _writeSyncLog(
        entityType: SheetConstants.categories,
        action: 'pull',
        status: 'success',
        syncedAt: lastServerTime,
      );

      currentStage = 'pull Transactions';
      _logStageStart(currentStage, webAppUrl);
      final SpreadsheetSyncResponse pullTransactionsResponse =
          await _spreadsheetSyncService.pull(
            webAppUrl: webAppUrl,
            token: token,
            entity: SheetConstants.transactions,
            since: settings.lastSpreadsheetPullAt,
          );
      pulledTransactions = await _mergeTransactions(
        pullTransactionsResponse.items,
      );
      lastServerTime = pullTransactionsResponse.serverTime ?? lastServerTime;
      _logStageSuccess(currentStage, pullTransactionsResponse);
      await _writeSyncLog(
        entityType: SheetConstants.transactions,
        action: 'pull',
        status: 'success',
        syncedAt: lastServerTime,
      );

      currentStage = 'pull Stock_Transactions';
      _logStageStart(currentStage, webAppUrl);
      final SpreadsheetSyncResponse pullStockTransactionsResponse =
          await _spreadsheetSyncService.pull(
            webAppUrl: webAppUrl,
            token: token,
            entity: SheetConstants.stockTransactions,
            since: settings.lastSpreadsheetPullAt,
          );
      pulledStockTransactions = await _mergeStockTransactions(
        pullStockTransactionsResponse.items,
      );
      lastServerTime =
          pullStockTransactionsResponse.serverTime ?? lastServerTime;
      _logStageSuccess(currentStage, pullStockTransactionsResponse);
      await _writeSyncLog(
        entityType: SheetConstants.stockTransactions,
        action: 'pull',
        status: 'success',
        syncedAt: lastServerTime,
      );

      currentStage = 'pull Dividends';
      _logStageStart(currentStage, webAppUrl);
      final SpreadsheetSyncResponse pullDividendsResponse =
          await _spreadsheetSyncService.pull(
            webAppUrl: webAppUrl,
            token: token,
            entity: SheetConstants.dividends,
            since: settings.lastSpreadsheetPullAt,
          );
      pulledDividends = await _mergeDividends(pullDividendsResponse.items);
      lastServerTime = pullDividendsResponse.serverTime ?? lastServerTime;
      _logStageSuccess(currentStage, pullDividendsResponse);
      await _writeSyncLog(
        entityType: SheetConstants.dividends,
        action: 'pull',
        status: 'success',
        syncedAt: lastServerTime,
      );

      final DateTime completedAt = lastServerTime ?? DateTimeUtils.utcNow();
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: completedAt,
        lastSpreadsheetPullAt: completedAt,
        status: 'success',
        message: 'Sinkronisasi spreadsheet berhasil.',
      );

      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: completedAt,
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        status: 'success',
        message: 'Sinkronisasi spreadsheet berhasil.',
      );
    } on SpreadsheetSyncException catch (error) {
      final String message = _buildStageFailureMessage(
        currentStage: currentStage,
        baseMessage: error.message,
      );
      _logStageFailure(currentStage, message);
      await _markPushFailure(
        categories: categoriesToPush,
        transactions: transactionsToPush,
        stockTransactions: stockTransactionsToPush,
        dividends: dividendsToPush,
        message: message,
      );
      await _writeSyncLog(
        entityType: 'spreadsheet',
        action: currentStage,
        status: 'failed',
        errorMessage: message,
      );
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: DateTimeUtils.utcNow(),
        status: 'failed',
        message: message,
      );
      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: DateTimeUtils.utcNow(),
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        status: 'failed',
        message: message,
      );
    } on FormatException catch (error) {
      final String message = _buildStageFailureMessage(
        currentStage: currentStage,
        baseMessage: error.message,
      );
      _logStageFailure(currentStage, message);
      await _markPushFailure(
        categories: categoriesToPush,
        transactions: transactionsToPush,
        stockTransactions: stockTransactionsToPush,
        dividends: dividendsToPush,
        message: message,
      );
      await _writeSyncLog(
        entityType: 'spreadsheet',
        action: 'sync',
        status: 'failed',
        errorMessage: message,
      );
      await _appSettingRepository.updateSpreadsheetSyncState(
        lastSpreadsheetSyncAt: DateTimeUtils.utcNow(),
        status: 'failed',
        message: message,
      );
      return SyncRunSummary(
        startedAt: startedAt,
        completedAt: DateTimeUtils.utcNow(),
        pushedCategories: pushedCategories,
        pushedTransactions: pushedTransactions,
        pushedStockTransactions: pushedStockTransactions,
        pushedDividends: pushedDividends,
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
        pulledStockTransactions: pulledStockTransactions,
        pulledDividends: pulledDividends,
        status: 'failed',
        message: message,
      );
    }
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

  Future<int> _mergeCategories(List<Map<String, dynamic>> payloads) async {
    var changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final Category remote = SpreadsheetSyncMapper.categoryFromPayload(
        payload,
      );
      remote.createdAt = DateTimeUtils.normalizeUtc(remote.createdAt);
      remote.updatedAt = DateTimeUtils.normalizeUtc(remote.updatedAt);
      if (remote.deletedAt != null) {
        remote.deletedAt = DateTimeUtils.normalizeUtc(remote.deletedAt!);
      }
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      if (!remote.updatedAt.isAfter(localUpdatedAt)) {
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
    var changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final MoneyTransaction remote =
          SpreadsheetSyncMapper.transactionFromPayload(payload);
      remote.transactionDate = DateTimeUtils.normalizeUtc(
        remote.transactionDate,
      );
      remote.createdAt = DateTimeUtils.normalizeUtc(remote.createdAt);
      remote.updatedAt = DateTimeUtils.normalizeUtc(remote.updatedAt);
      if (remote.deletedAt != null) {
        remote.deletedAt = DateTimeUtils.normalizeUtc(remote.deletedAt!);
      }
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      if (!remote.updatedAt.isAfter(localUpdatedAt)) {
        continue;
      }

      remote.id = local.id;
      remote.syncStatus = 'synced';
      remote.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.moneyTransactions.put(remote);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeStockTransactions(
    List<Map<String, dynamic>> payloads,
  ) async {
    var changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final StockTransaction remote =
          SpreadsheetSyncMapper.stockTransactionFromPayload(payload);
      remote.transactionDate = DateTimeUtils.normalizeUtc(
        remote.transactionDate,
      );
      remote.createdAt = DateTimeUtils.normalizeUtc(remote.createdAt);
      remote.updatedAt = DateTimeUtils.normalizeUtc(remote.updatedAt);
      if (remote.deletedAt != null) {
        remote.deletedAt = DateTimeUtils.normalizeUtc(remote.deletedAt!);
      }
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      if (!remote.updatedAt.isAfter(localUpdatedAt)) {
        continue;
      }

      remote.id = local.id;
      remote.syncStatus = 'synced';
      remote.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.stockTransactions.put(remote);
      });
      changed++;
    }

    return changed;
  }

  Future<int> _mergeDividends(List<Map<String, dynamic>> payloads) async {
    var changed = 0;

    for (final Map<String, dynamic> payload in payloads) {
      final Dividend remote = SpreadsheetSyncMapper.dividendFromPayload(
        payload,
      );
      remote.receivedDate = DateTimeUtils.normalizeUtc(remote.receivedDate);
      remote.createdAt = DateTimeUtils.normalizeUtc(remote.createdAt);
      remote.updatedAt = DateTimeUtils.normalizeUtc(remote.updatedAt);
      if (remote.deletedAt != null) {
        remote.deletedAt = DateTimeUtils.normalizeUtc(remote.deletedAt!);
      }
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      if (!remote.updatedAt.isAfter(localUpdatedAt)) {
        continue;
      }

      remote.id = local.id;
      remote.syncStatus = 'synced';
      remote.syncErrorMessage = null;
      await _isar.writeTxn(() async {
        await _isar.dividends.put(remote);
      });
      changed++;
    }

    return changed;
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

  Future<void> _markPushFailure({
    required List<Category> categories,
    required List<MoneyTransaction> transactions,
    required List<StockTransaction> stockTransactions,
    required List<Dividend> dividends,
    required String message,
  }) async {
    await _isar.writeTxn(() async {
      for (final Category item in categories) {
        if (item.syncStatus == 'synced') {
          continue;
        }
        item.syncStatus = 'failed';
        item.syncErrorMessage = message;
      }
      if (categories.isNotEmpty) {
        await _isar.categorys.putAll(categories);
      }

      for (final MoneyTransaction item in transactions) {
        if (item.syncStatus == 'synced') {
          continue;
        }
        item.syncStatus = 'failed';
        item.syncErrorMessage = message;
      }
      if (transactions.isNotEmpty) {
        await _isar.moneyTransactions.putAll(transactions);
      }

      for (final StockTransaction item in stockTransactions) {
        if (item.syncStatus == 'synced') {
          continue;
        }
        item.syncStatus = 'failed';
        item.syncErrorMessage = message;
      }
      if (stockTransactions.isNotEmpty) {
        await _isar.stockTransactions.putAll(stockTransactions);
      }

      for (final Dividend item in dividends) {
        if (item.syncStatus == 'synced') {
          continue;
        }
        item.syncStatus = 'failed';
        item.syncErrorMessage = message;
      }
      if (dividends.isNotEmpty) {
        await _isar.dividends.putAll(dividends);
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
}

class SyncRunSummary {
  const SyncRunSummary({
    required this.startedAt,
    required this.completedAt,
    required this.pushedCategories,
    required this.pushedTransactions,
    required this.pushedStockTransactions,
    required this.pushedDividends,
    required this.pulledCategories,
    required this.pulledTransactions,
    required this.pulledStockTransactions,
    required this.pulledDividends,
    required this.status,
    required this.message,
  });

  final DateTime startedAt;
  final DateTime completedAt;
  final int pushedCategories;
  final int pushedTransactions;
  final int pushedStockTransactions;
  final int pushedDividends;
  final int pulledCategories;
  final int pulledTransactions;
  final int pulledStockTransactions;
  final int pulledDividends;
  final String status;
  final String message;
}
