import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/session/app_session_controller.dart';
import 'data/local/local_database_service.dart';
import 'data/repositories/app_setting_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/voice_transcript_repository.dart';

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
      categoryRepository: categoryRepository,
      transactionRepository: transactionRepository,
      voiceTranscriptRepository: voiceTranscriptRepository,
    ),
  );
}
