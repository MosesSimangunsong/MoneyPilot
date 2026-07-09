import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/app_setting_repository.dart';
import '../constants/app_constants.dart';
import '../../data/services/biometric_service.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    BiometricService? biometricService,
    AppSettingRepository? appSettingRepository,
  }) : _biometricService = biometricService ?? BiometricService(),
       _appSettingRepository = appSettingRepository;

  static const String _onboardingKey = 'app.onboardingCompleted';
  static const String _nameKey = 'app.userName';
  static const String _biometricEnabledKey = 'app.biometricEnabled';

  final BiometricService _biometricService;
  final AppSettingRepository? _appSettingRepository;

  bool _isInitialized = false;
  bool _hasCompletedOnboarding = false;
  bool _biometricEnabled = true;
  bool _biometricSupported = false;
  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  String _userName = 'Teman';
  DateTime? _pausedAt;

  bool get isInitialized => _isInitialized;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricSupported => _biometricSupported;
  bool get isUnlocked => _isUnlocked;
  bool get isAuthenticating => _isAuthenticating;
  String get userName => _userName;

  bool get requiresBiometricLock =>
      _hasCompletedOnboarding && _biometricEnabled && _biometricSupported;

  Future<void> initialize() async {
    await Future<void>.delayed(AppConstants.splashDelay);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = preferences.getBool(_onboardingKey) ?? false;
    _userName = preferences.getString(_nameKey) ?? 'Teman';
    _biometricEnabled = preferences.getBool(_biometricEnabledKey) ?? true;
    _biometricSupported = await _biometricService.isAvailable();
    _isUnlocked = !requiresBiometricLock;
    await _appSettingRepository?.ensureSeeded(
      userName: _userName,
      biometricEnabled: _biometricEnabled,
    );
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String userName,
    required bool enableBiometric,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _userName = userName.trim();
    _hasCompletedOnboarding = true;
    _biometricEnabled = enableBiometric && _biometricSupported;
    _isUnlocked = !requiresBiometricLock;
    await preferences.setString(_nameKey, _userName);
    await preferences.setBool(_onboardingKey, true);
    await preferences.setBool(_biometricEnabledKey, _biometricEnabled);
    await _appSettingRepository?.ensureSeeded(
      userName: _userName,
      biometricEnabled: _biometricEnabled,
    );
    notifyListeners();
  }

  Future<bool> unlock() async {
    if (!requiresBiometricLock) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }

    if (_isAuthenticating) {
      return false;
    }

    _isAuthenticating = true;
    notifyListeners();

    final bool success = await _biometricService.authenticate();

    _isAuthenticating = false;
    if (success) {
      _isUnlocked = true;
      _pausedAt = null;
    }
    notifyListeners();
    return success;
  }

  void handleLifecycleChange(AppLifecycleState state) {
    if (!_hasCompletedOnboarding || !requiresBiometricLock) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now().toUtc();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _pausedAt != null &&
        DateTime.now().toUtc().difference(_pausedAt!) >=
            AppConstants.relockDelay) {
      _isUnlocked = false;
      _pausedAt = null;
      notifyListeners();
    }
  }
}
