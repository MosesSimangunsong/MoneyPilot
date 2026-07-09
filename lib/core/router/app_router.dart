import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/analisis/analisis_screen.dart';
import '../../features/beranda/beranda_screen.dart';
import '../../features/berita/berita_screen.dart';
import '../../features/keuangan/keuangan_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/portofolio/portofolio_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../../features/startup/biometric_lock_screen.dart';
import '../../features/startup/splash_screen.dart';
import '../../data/repositories/category_repository.dart';
import '../constants/route_constants.dart';
import '../session/app_session_controller.dart';

class AppRouter {
  AppRouter(
    this._sessionController, {
    required CategoryRepository categoryRepository,
  }) : _categoryRepository = categoryRepository;

  final AppSessionController _sessionController;
  final CategoryRepository _categoryRepository;

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
                    categoryRepository: _categoryRepository,
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
                  return const BeritaScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.keuangan,
                builder: (BuildContext context, GoRouterState state) {
                  return const KeuanganScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RouteConstants.portofolio,
                builder: (BuildContext context, GoRouterState state) {
                  return const PortofolioScreen();
                },
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
