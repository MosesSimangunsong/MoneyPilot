import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/session/app_session_controller.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_database_service.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/app_setting_repository.dart';
import 'data/repositories/portfolio_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/voice_transcript_repository.dart';

class MoneyPilotApp extends StatefulWidget {
  const MoneyPilotApp({
    super.key,
    required this.sessionController,
    required this.databaseService,
    required this.appSettingRepository,
    required this.categoryRepository,
    required this.portfolioRepository,
    required this.syncRepository,
    required this.transactionRepository,
    required this.voiceTranscriptRepository,
  });

  final AppSessionController sessionController;
  final LocalDatabaseService databaseService;
  final AppSettingRepository appSettingRepository;
  final CategoryRepository categoryRepository;
  final PortfolioRepository portfolioRepository;
  final SyncRepository syncRepository;
  final TransactionRepository transactionRepository;
  final VoiceTranscriptRepository voiceTranscriptRepository;

  @override
  State<MoneyPilotApp> createState() => _MoneyPilotAppState();
}

class _MoneyPilotAppState extends State<MoneyPilotApp>
    with WidgetsBindingObserver {
  late final AppSessionController _sessionController;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionController = widget.sessionController;
    _appRouter = AppRouter(
      _sessionController,
      appSettingRepository: widget.appSettingRepository,
      categoryRepository: widget.categoryRepository,
      portfolioRepository: widget.portfolioRepository,
      syncRepository: widget.syncRepository,
      transactionRepository: widget.transactionRepository,
      voiceTranscriptRepository: widget.voiceTranscriptRepository,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sessionController.handleLifecycleChange(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionController.dispose();
    widget.databaseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MoneyPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.router,
    );
  }
}
