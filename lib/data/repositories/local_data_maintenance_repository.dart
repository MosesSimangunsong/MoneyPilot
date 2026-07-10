import 'package:isar/isar.dart';

import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/sync_log.dart';
import '../models/voice_transcript.dart';
import '../models/watchlist_item.dart';
import 'category_repository.dart';

class LocalDataMaintenanceRepository {
  LocalDataMaintenanceRepository(this._isar);

  final Isar _isar;

  Future<void> resetAllLocalData() async {
    await _isar.writeTxn(() async {
      await _isar.moneyTransactions.clear();
      await _isar.stockTransactions.clear();
      await _isar.dividends.clear();
      await _isar.watchlistItems.clear();
      await _isar.voiceTranscripts.clear();
      await _isar.syncLogs.clear();
      await _isar.categorys.clear();
    });

    await CategoryRepository(_isar).seedDefaultCategoriesIfNeeded();
  }
}
