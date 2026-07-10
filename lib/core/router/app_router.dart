import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/analisis/analisis_screen.dart';
import '../../features/beranda/beranda_screen.dart';
import '../../features/berita/analisis_berita_screen.dart';
import '../../features/berita/berita_screen.dart';
import '../../features/berita/detail_berita_screen.dart';
import '../../features/keuangan/add_edit_transaction_screen.dart';
import '../../features/keuangan/keuangan_screen.dart';
import '../../features/keuangan/konfirmasi_suara_screen.dart';
import '../../features/keuangan/tambah_transaksi_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/portofolio/portofolio_screen.dart';
import '../../features/portofolio/tambah_dividen_screen.dart';
import '../../features/portofolio/tambah_transaksi_saham_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../../features/startup/biometric_lock_screen.dart';
import '../../features/startup/splash_screen.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/voice_transcript_repository.dart';
import '../../data/services/market_data_api_service.dart';
import '../../data/services/speech_service.dart';
import '../../data/services/transaction_parser_service.dart';
import '../constants/route_constants.dart';
import '../session/app_session_controller.dart';

class AppRouter {
  AppRouter(
    this._sessionController, {
    required AppSettingRepository appSettingRepository,
    required CategoryRepository categoryRepository,
    required PortfolioRepository portfolioRepository,
    required MarketDataApiService marketDataApiService,
    required NewsRepository newsRepository,
    required SyncRepository syncRepository,
    required TransactionRepository transactionRepository,
    required VoiceTranscriptRepository voiceTranscriptRepository,
  }) : _appSettingRepository = appSettingRepository,
       _categoryRepository = categoryRepository,
       _portfolioRepository = portfolioRepository,
       _marketDataApiService = marketDataApiService,
       _newsRepository = newsRepository,
       _syncRepository = syncRepository,
       _transactionRepository = transactionRepository,
       _voiceTranscriptRepository = voiceTranscriptRepository;

  final AppSessionController _sessionController;
  final AppSettingRepository _appSettingRepository;
  final CategoryRepository _categoryRepository;
  final PortfolioRepository _portfolioRepository;
  final MarketDataApiService _marketDataApiService;
  final NewsRepository _newsRepository;
  final SyncRepository _syncRepository;
  final TransactionRepository _transactionRepository;
  final VoiceTranscriptRepository _voiceTranscriptRepository;
  final SpeechService _speechService = SpeechService();
  final TransactionParserService _parserService =
      const TransactionParserService();

  late final GoRouter router = GoRouter(
    initialLocation: RouteConstants.splash,
    refreshListenable: _sessionController,
    redirect: _redirect,
    routes: <RouteBase>[
      GoRoute(
        path: RouteConstants.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          return OnboardingScreen(sessionController: _sessionController);
        },
      ),
      GoRoute(
        path: RouteConstants.biometricLock,
        builder: (BuildContext context, GoRouterState state) {
          return BiometricLockScreen(sessionController: _sessionController);
        },
      ),
      GoRoute(
        path: RouteConstants.settings,
        builder: (BuildContext context, GoRouterState state) {
          return SettingsScreen(
            appSettingRepository: _appSettingRepository,
            syncRepository: _syncRepository,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainShellScreen(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.beranda,
                builder: (BuildContext context, GoRouterState state) {
                  return BerandaScreen(
                    sessionController: _sessionController,
                    appSettingRepository: _appSettingRepository,
                    categoryRepository: _categoryRepository,
                    syncRepository: _syncRepository,
                    transactionRepository: _transactionRepository,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.berita,
                builder: (BuildContext context, GoRouterState state) {
                  return BeritaScreen(newsRepository: _newsRepository);
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'detail',
                    builder: (BuildContext context, GoRouterState state) {
                      final NewsRouteArguments arguments =
                          state.extra! as NewsRouteArguments;
                      return DetailBeritaScreen(
                        newsRepository: _newsRepository,
                        arguments: arguments,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'analisis',
                    builder: (BuildContext context, GoRouterState state) {
                      final NewsRouteArguments arguments =
                          state.extra! as NewsRouteArguments;
                      return AnalisisBeritaScreen(
                        newsRepository: _newsRepository,
                        arguments: arguments,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.keuangan,
                builder: (BuildContext context, GoRouterState state) {
                  return KeuanganScreen(
                    appSettingRepository: _appSettingRepository,
                    syncRepository: _syncRepository,
                    transactionRepository: _transactionRepository,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'transaksi-baru',
                    builder: (BuildContext context, GoRouterState state) {
                      final AddEditTransactionArguments? arguments =
                          state.extra as AddEditTransactionArguments?;
                      return AddEditTransactionScreen(
                        categoryRepository: _categoryRepository,
                        transactionRepository: _transactionRepository,
                        arguments: arguments,
                        voiceTranscriptRepository: _voiceTranscriptRepository,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':uuid/edit',
                    builder: (BuildContext context, GoRouterState state) {
                      return AddEditTransactionScreen(
                        categoryRepository: _categoryRepository,
                        transactionRepository: _transactionRepository,
                        transactionUuid: state.pathParameters['uuid'],
                        voiceTranscriptRepository: _voiceTranscriptRepository,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'suara',
                    builder: (BuildContext context, GoRouterState state) {
                      return VoiceInputScreen(
                        speechService: _speechService,
                        parserService: _parserService,
                        categoryRepository: _categoryRepository,
                        voiceTranscriptRepository: _voiceTranscriptRepository,
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'konfirmasi',
                        builder: (BuildContext context, GoRouterState state) {
                          final VoiceConfirmationArguments arguments =
                              state.extra! as VoiceConfirmationArguments;
                          return VoiceConfirmationScreen(
                            arguments: arguments,
                            categoryRepository: _categoryRepository,
                            transactionRepository: _transactionRepository,
                            voiceTranscriptRepository:
                                _voiceTranscriptRepository,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.portofolio,
                builder: (BuildContext context, GoRouterState state) {
                  return PortofolioScreen(
                    portfolioRepository: _portfolioRepository,
                    marketDataApiService: _marketDataApiService,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'transaksi-saham-baru',
                    builder: (BuildContext context, GoRouterState state) {
                      return TambahTransaksiSahamScreen(
                        portfolioRepository: _portfolioRepository,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'catat-dividen',
                    builder: (BuildContext context, GoRouterState state) {
                      return TambahDividenScreen(
                        portfolioRepository: _portfolioRepository,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':uuid/edit',
                    builder: (BuildContext context, GoRouterState state) {
                      return TambahTransaksiSahamScreen(
                        portfolioRepository: _portfolioRepository,
                        transactionUuid: state.pathParameters['uuid'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.analisis,
                builder: (BuildContext context, GoRouterState state) {
                  return const AnalisisScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final String currentLocation = state.uri.path;

    if (!_sessionController.isInitialized) {
      return currentLocation == RouteConstants.splash
          ? null
          : RouteConstants.splash;
    }

    if (!_sessionController.hasCompletedOnboarding) {
      return currentLocation == RouteConstants.onboarding
          ? null
          : RouteConstants.onboarding;
    }

    if (_sessionController.requiresBiometricLock &&
        !_sessionController.isUnlocked) {
      return currentLocation == RouteConstants.biometricLock
          ? null
          : RouteConstants.biometricLock;
    }

    if (currentLocation == RouteConstants.splash ||
        currentLocation == RouteConstants.onboarding ||
        currentLocation == RouteConstants.biometricLock) {
      return RouteConstants.beranda;
    }

    return null;
  }
}
