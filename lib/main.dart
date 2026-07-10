import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/session/app_session_controller.dart';
import 'data/local/local_database_service.dart';
import 'data/repositories/app_setting_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/portfolio_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/voice_transcript_repository.dart';
import 'data/services/market_data_api_service.dart';
import 'data/services/spreadsheet_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LocalDatabaseService databaseService = LocalDatabaseService();
  await databaseService.init();

  final AppSettingRepository appSettingRepository = AppSettingRepository(
    databaseService.isar,
  );
  await appSettingRepository.getOrCreateSettings();

  final CategoryRepository categoryRepository = CategoryRepository(
    databaseService.isar,
  );
  await categoryRepository.seedDefaultCategoriesIfNeeded();
  final TransactionRepository transactionRepository = TransactionRepository(
    databaseService.isar,
  );
  final PortfolioRepository portfolioRepository = PortfolioRepository(
    databaseService.isar,
  );
  final MarketDataApiService marketDataApiService = MarketDataApiService();
  final SyncRepository syncRepository = SyncRepository(
    databaseService.isar,
    appSettingRepository: appSettingRepository,
    spreadsheetSyncService: SpreadsheetSyncService(),
  );
  final VoiceTranscriptRepository voiceTranscriptRepository =
      VoiceTranscriptRepository(databaseService.isar);

  final AppSessionController sessionController = AppSessionController(
    appSettingRepository: appSettingRepository,
  );
  await sessionController.initialize();

  runApp(
    MoneyPilotApp(
      sessionController: sessionController,
      databaseService: databaseService,
      appSettingRepository: appSettingRepository,
      categoryRepository: categoryRepository,
      portfolioRepository: portfolioRepository,
      marketDataApiService: marketDataApiService,
      syncRepository: syncRepository,
      transactionRepository: transactionRepository,
      voiceTranscriptRepository: voiceTranscriptRepository,
    ),
  );
}
