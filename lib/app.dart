import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/session/app_session_controller.dart';
import 'core/theme/app_theme.dart';

class MoneyPilotApp extends StatefulWidget {
  const MoneyPilotApp({super.key});

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
    _sessionController = AppSessionController();
    _appRouter = AppRouter(_sessionController);
    _sessionController.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sessionController.handleLifecycleChange(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionController.dispose();
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
