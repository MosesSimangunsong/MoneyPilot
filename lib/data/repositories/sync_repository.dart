import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import '../../core/constants/sheet_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/category.dart';
import '../models/money_transaction.dart';
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

  Future<int> countPendingSyncItems() async {
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
    return pendingCategories + pendingTransactions;
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

    DateTime? lastServerTime;
    String currentStage = 'persiapan sync';
    int pushedCategories = 0;
    int pushedTransactions = 0;
    int pulledCategories = 0;
    int pulledTransactions = 0;

    try {
      final SpreadsheetSyncResponse? categoryPushResponse =
          await pushCategoriesIfNeeded(
            webAppUrl: webAppUrl,
            token: token,
            categories: categoriesToPush,
          );
      if (categoryPushResponse != null) {
        currentStage = 'push Categories';
        pushedCategories = categoriesToPush.length;
        lastServerTime = categoryPushResponse.serverTime ?? lastServerTime;
      }

      final SpreadsheetSyncResponse? transactionPushResponse =
          await pushPendingTransactions(
            webAppUrl: webAppUrl,
            token: token,
            transactions: transactionsToPush,
          );
      if (transactionPushResponse != null) {
        currentStage = 'push Transactions';
        pushedTransactions = transactionsToPush.length;
        lastServerTime = transactionPushResponse.serverTime ?? lastServerTime;
      }

      final SpreadsheetSyncResponse pullCategoriesResponse =
          await pullCategories(
            webAppUrl: webAppUrl,
            token: token,
            since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
          );
      currentStage = 'pull Categories';
      pulledCategories = await _mergeCategories(pullCategoriesResponse.items);
      lastServerTime = pullCategoriesResponse.serverTime ?? lastServerTime;

      final SpreadsheetSyncResponse pullTransactionsResponse =
          await pullTransactions(
            webAppUrl: webAppUrl,
            token: token,
            since: settings.lastSpreadsheetPullAt?.toUtc().toIso8601String(),
          );
      currentStage = 'pull Transactions';
      pulledTransactions = await _mergeTransactions(
        pullTransactionsResponse.items,
      );
      lastServerTime = pullTransactionsResponse.serverTime ?? lastServerTime;

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
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
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
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
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
        pulledCategories: pulledCategories,
        pulledTransactions: pulledTransactions,
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      final DateTime remoteUpdatedAt = DateTimeUtils.normalizeUtc(
        remote.updatedAt,
      );
      if (!remoteUpdatedAt.isAfter(localUpdatedAt)) {
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

      final DateTime localUpdatedAt = DateTimeUtils.normalizeUtc(
        local.updatedAt,
      );
      final DateTime remoteUpdatedAt = DateTimeUtils.normalizeUtc(
        remote.updatedAt,
      );
      if (!remoteUpdatedAt.isAfter(localUpdatedAt)) {
        continue;
      }

      if (remote.isDeleted) {
        local.isDeleted = true;
        local.deletedAt = remote.deletedAt ?? remoteUpdatedAt;
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

  Future<void> _markPushFailure({
    required List<Category> categories,
    required List<MoneyTransaction> transactions,
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
    required this.pulledCategories,
    required this.pulledTransactions,
    required this.pendingCount,
    required this.status,
    required this.message,
  });

  final DateTime startedAt;
  final DateTime completedAt;
  final int pushedCategories;
  final int pushedTransactions;
  final int pulledCategories;
  final int pulledTransactions;
  final int pendingCount;
  final String status;
  final String message;
}
