import 'package:isar/isar.dart';

import '../models/app_setting.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/sync_log.dart';
import '../models/voice_transcript.dart';
import '../models/watchlist_item.dart';

const List<CollectionSchema<dynamic>> moneyPilotSchemas =
    <CollectionSchema<dynamic>>[
      AppSettingSchema,
      CategorySchema,
      MoneyTransactionSchema,
      StockTransactionSchema,
      DividendSchema,
      WatchlistItemSchema,
      VoiceTranscriptSchema,
      SyncLogSchema,
    ];
