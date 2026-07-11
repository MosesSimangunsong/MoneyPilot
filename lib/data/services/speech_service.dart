import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechServiceState {
  unavailable,
  idle,
  listening,
  processing,
  completed,
  error,
}

enum SpeechServiceFailure {
  microphoneDenied,
  microphonePermanentlyDenied,
  speechUnavailable,
  localeUnavailable,
  recognizerBusy,
  noMatch,
  audioError,
  network,
  unknown,
}

class SpeechPreparationResult {
  const SpeechPreparationResult({
    required this.isReady,
    required this.state,
    required this.message,
    this.failure,
    this.shouldOpenSettings = false,
    this.localeId,
  });

  final bool isReady;
  final SpeechServiceState state;
  final String message;
  final SpeechServiceFailure? failure;
  final bool shouldOpenSettings;
  final String? localeId;
}

class SpeechRecognitionUpdate {
  const SpeechRecognitionUpdate({
    required this.transcript,
    required this.isFinal,
    required this.confidence,
  });

  final String transcript;
  final bool isFinal;
  final double confidence;
}

class SpeechServiceStatus {
  const SpeechServiceStatus({
    required this.state,
    required this.message,
    this.failure,
    this.localeId,
    this.shouldOpenSettings = false,
  });

  final SpeechServiceState state;
  final String message;
  final SpeechServiceFailure? failure;
  final String? localeId;
  final bool shouldOpenSettings;
}

class SpeechService {
  SpeechService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  bool _isInitialized = false;
  String? _selectedLocaleId;
  SpeechServiceStatus _status = const SpeechServiceStatus(
    state: SpeechServiceState.idle,
    message: 'Tekan tombol mulai untuk merekam transaksi suara.',
  );

  SpeechServiceStatus get status => _status;

  Future<bool> get hasPermission async {
    final PermissionStatus permissionStatus =
        await Permission.microphone.status;
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      return true;
    }
    return _speechToText.hasPermission;
  }

  bool get isListening => _speechToText.isListening;

  String? get selectedLocaleId => _selectedLocaleId;

  Future<SpeechPreparationResult> prepare({
    bool requestPermission = false,
    void Function(String status)? onStatus,
    void Function(SpeechServiceFailure failure, String message)? onError,
  }) async {
    final PermissionStatus permissionStatus = requestPermission
        ? await Permission.microphone.request()
        : await Permission.microphone.status;

    if (permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted) {
      return _updatePreparation(
        SpeechPreparationResult(
          isReady: false,
          state: SpeechServiceState.error,
          failure: SpeechServiceFailure.microphonePermanentlyDenied,
          shouldOpenSettings: true,
          message:
              'Izin mikrofon dinonaktifkan secara permanen. Aktifkan melalui Pengaturan perangkat.',
        ),
      );
    }

    if (!permissionStatus.isGranted && !permissionStatus.isLimited) {
      return _updatePreparation(
        SpeechPreparationResult(
          isReady: false,
          state: SpeechServiceState.error,
          failure: SpeechServiceFailure.microphoneDenied,
          message:
              'Izin mikrofon diperlukan untuk mencatat transaksi melalui suara.',
        ),
      );
    }

    final bool initialized = await _ensureInitialized(
      onStatus: onStatus,
      onError: onError,
    );
    if (!initialized) {
      return _updatePreparation(
        SpeechPreparationResult(
          isReady: false,
          state: SpeechServiceState.unavailable,
          failure: SpeechServiceFailure.speechUnavailable,
          message:
              'Pengenalan suara sedang tidak tersedia. Silakan coba lagi atau gunakan input manual.',
        ),
      );
    }

    final List<LocaleName> locales = await _speechToText.locales();
    final LocaleName? preferredLocale = _selectIndonesianLocale(locales);
    if (preferredLocale == null) {
      return _updatePreparation(
        SpeechPreparationResult(
          isReady: false,
          state: SpeechServiceState.unavailable,
          failure: SpeechServiceFailure.localeUnavailable,
          message:
              'Bahasa Indonesia belum tersedia pada layanan pengenalan suara perangkat ini.',
        ),
      );
    }

    _selectedLocaleId = preferredLocale.localeId;
    return _updatePreparation(
      SpeechPreparationResult(
        isReady: true,
        state: SpeechServiceState.idle,
        message: 'Siap mendengarkan transaksi dalam Bahasa Indonesia.',
        localeId: _selectedLocaleId,
      ),
    );
  }

  Future<bool> startListening({
    required void Function(SpeechRecognitionUpdate update) onResult,
    void Function(SpeechServiceFailure failure, String message)? onError,
    void Function(String status)? onStatus,
    void Function(double level)? onSoundLevelChange,
  }) async {
    final SpeechPreparationResult preparation = await prepare(
      requestPermission: true,
      onStatus: onStatus,
      onError: onError,
    );
    if (!preparation.isReady) {
      return false;
    }

    _status = SpeechServiceStatus(
      state: SpeechServiceState.listening,
      message: 'Sedang mendengarkan...',
      localeId: _selectedLocaleId,
    );

    try {
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          localeId: _selectedLocaleId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 20),
        ),
        onSoundLevelChange: onSoundLevelChange,
        onResult: (SpeechRecognitionResult result) {
          onResult(
            SpeechRecognitionUpdate(
              transcript: result.recognizedWords.trim(),
              isFinal: result.finalResult,
              confidence: result.confidence,
            ),
          );
        },
      );
      return true;
    } on ListenFailedException catch (_) {
      final SpeechServiceFailure failure = _mapSpeechError(
        _speechToText.lastError,
      );
      final String message = _mapSpeechErrorMessage(failure);
      _status = SpeechServiceStatus(
        state: SpeechServiceState.error,
        message: message,
        failure: failure,
        localeId: _selectedLocaleId,
      );
      onError?.call(failure, message);
      return false;
    } on SpeechToTextNotInitializedException {
      const SpeechServiceFailure failure =
          SpeechServiceFailure.speechUnavailable;
      const String message =
          'Pengenalan suara sedang tidak tersedia. Silakan coba lagi atau gunakan input manual.';
      _status = const SpeechServiceStatus(
        state: SpeechServiceState.error,
        message: message,
        failure: failure,
      );
      onError?.call(failure, message);
      return false;
    }
  }

  Future<void> stopListening({bool markProcessing = true}) async {
    if (markProcessing) {
      _status = SpeechServiceStatus(
        state: SpeechServiceState.processing,
        message: 'Memproses hasil suara...',
        localeId: _selectedLocaleId,
      );
    }
    await _speechToText.stop();
  }

  Future<void> cancelListening({String? message}) async {
    await _speechToText.cancel();
    _status = SpeechServiceStatus(
      state: SpeechServiceState.idle,
      message: message ?? 'Perekaman suara dibatalkan.',
      localeId: _selectedLocaleId,
    );
  }

  void markCompleted({String? message}) {
    _status = SpeechServiceStatus(
      state: SpeechServiceState.completed,
      message: message ?? 'Hasil suara siap diperiksa.',
      localeId: _selectedLocaleId,
    );
  }

  void markProcessing([String message = 'Memproses hasil suara...']) {
    _status = SpeechServiceStatus(
      state: SpeechServiceState.processing,
      message: message,
      localeId: _selectedLocaleId,
    );
  }

  void markIdle([
    String message = 'Tekan tombol mulai untuk merekam transaksi suara.',
  ]) {
    _status = SpeechServiceStatus(
      state: SpeechServiceState.idle,
      message: message,
      localeId: _selectedLocaleId,
    );
  }

  void markError(
    SpeechServiceFailure failure,
    String message, {
    bool shouldOpenSettings = false,
  }) {
    _status = SpeechServiceStatus(
      state: SpeechServiceState.error,
      message: message,
      failure: failure,
      localeId: _selectedLocaleId,
      shouldOpenSettings: shouldOpenSettings,
    );
  }

  Future<bool> openPermissionSettings() {
    return openAppSettings();
  }

  Future<bool> _ensureInitialized({
    void Function(String status)? onStatus,
    void Function(SpeechServiceFailure failure, String message)? onError,
  }) async {
    if (_isInitialized) {
      return true;
    }
    final bool initialized = await _speechToText.initialize(
      onStatus: onStatus,
      onError: (SpeechRecognitionError error) {
        final SpeechServiceFailure failure = _mapSpeechError(error);
        final String message = _mapSpeechErrorMessage(failure);
        _status = SpeechServiceStatus(
          state: SpeechServiceState.error,
          message: message,
          failure: failure,
          localeId: _selectedLocaleId,
        );
        onError?.call(failure, message);
      },
    );
    _isInitialized = initialized;
    return initialized;
  }

  LocaleName? _selectIndonesianLocale(List<LocaleName> locales) {
    for (final LocaleName locale in locales) {
      if (locale.localeId.toLowerCase() == 'id_id') {
        return locale;
      }
    }
    for (final LocaleName locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('id')) {
        return locale;
      }
    }
    return null;
  }

  SpeechPreparationResult _updatePreparation(SpeechPreparationResult result) {
    _status = SpeechServiceStatus(
      state: result.state,
      message: result.message,
      failure: result.failure,
      localeId: result.localeId,
      shouldOpenSettings: result.shouldOpenSettings,
    );
    return result;
  }

  SpeechServiceFailure _mapSpeechError(SpeechRecognitionError? error) {
    final String code = error?.errorMsg.trim().toLowerCase() ?? '';
    if (code.contains('permission')) {
      return SpeechServiceFailure.microphoneDenied;
    }
    if (code.contains('busy')) {
      return SpeechServiceFailure.recognizerBusy;
    }
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return SpeechServiceFailure.noMatch;
    }
    if (code.contains('audio')) {
      return SpeechServiceFailure.audioError;
    }
    if (code.contains('network') || code.contains('server')) {
      return SpeechServiceFailure.network;
    }
    if (code.contains('language_not_supported') ||
        code.contains('language_unavailable')) {
      return SpeechServiceFailure.localeUnavailable;
    }
    return SpeechServiceFailure.unknown;
  }

  String _mapSpeechErrorMessage(SpeechServiceFailure failure) {
    switch (failure) {
      case SpeechServiceFailure.microphoneDenied:
        return 'Izin mikrofon ditolak. Anda tetap dapat mencatat transaksi secara manual.';
      case SpeechServiceFailure.microphonePermanentlyDenied:
        return 'Izin mikrofon dinonaktifkan secara permanen. Aktifkan melalui Pengaturan perangkat.';
      case SpeechServiceFailure.speechUnavailable:
        return 'Pengenalan suara sedang tidak tersedia. Silakan coba lagi atau gunakan input manual.';
      case SpeechServiceFailure.localeUnavailable:
        return 'Bahasa Indonesia belum tersedia pada layanan pengenalan suara perangkat ini.';
      case SpeechServiceFailure.recognizerBusy:
        return 'Mikrofon atau layanan pengenalan suara sedang digunakan aplikasi lain.';
      case SpeechServiceFailure.noMatch:
        return 'Ucapan belum terbaca dengan jelas. Silakan coba rekam lagi.';
      case SpeechServiceFailure.audioError:
        return 'Terjadi masalah pada mikrofon perangkat. Silakan coba lagi.';
      case SpeechServiceFailure.network:
        return 'Pengenalan suara sedang tidak tersedia. Silakan coba lagi atau gunakan input manual.';
      case SpeechServiceFailure.unknown:
        return 'Terjadi kendala saat memproses suara. Silakan coba lagi.';
    }
  }
}
