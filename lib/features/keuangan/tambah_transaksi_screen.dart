import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/voice_transcript_repository.dart';
import '../../data/services/speech_service.dart';
import '../../data/services/transaction_parser_service.dart';
import 'add_edit_transaction_screen.dart';
import 'konfirmasi_suara_screen.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({
    super.key,
    required this.speechService,
    required this.parserService,
    required this.categoryRepository,
    required this.voiceTranscriptRepository,
  });

  final SpeechService speechService;
  final TransactionParserService parserService;
  final CategoryRepository categoryRepository;
  final VoiceTranscriptRepository voiceTranscriptRepository;

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with WidgetsBindingObserver {
  String _transcript = '';
  String _statusText = 'Tekan tombol mulai untuk merekam transaksi suara.';
  bool _isPreparing = true;
  bool _isBusy = false;
  bool _canOpenSettings = false;
  double _soundLevel = 0;
  SpeechServiceState _serviceState = SpeechServiceState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.speechService.cancelListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!widget.speechService.isListening) {
        return;
      }
      widget.speechService.cancelListening(
        message:
            'Perekaman dihentikan karena aplikasi berpindah ke background.',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _serviceState = widget.speechService.status.state;
        _statusText = widget.speechService.status.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = widget.speechService.isListening;
    final bool isUnavailable = _serviceState == SpeechServiceState.unavailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Suara')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              'Ucapkan transaksi harianmu dalam Bahasa Indonesia. Hasilnya akan selalu diperiksa dulu sebelum disimpan.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: _statusBorderColor()),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 84 + (_soundLevel * 2),
                        height: 84 + (_soundLevel * 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? AppColors.primary.withValues(alpha: 0.10)
                              : AppColors.surface,
                        ),
                      ),
                      Icon(
                        isListening ? Icons.graphic_eq : LucideIcons.mic,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _stateLabel(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _transcript.isEmpty
                          ? 'Contoh: Beli nasi goreng dua puluh lima ribu hari ini'
                          : _transcript,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _transcript.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_serviceState == SpeechServiceState.error || isUnavailable)
              _buildStatusCard(context),
            if (_isPreparing) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ] else ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy || !isListening
                          ? null
                          : _stopAndProcess,
                      icon: const Icon(LucideIcons.square),
                      label: const Text('Berhenti'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy || isListening
                          ? null
                          : _startListening,
                      icon: const Icon(LucideIcons.mic),
                      label: Text(
                        isListening ? 'Mendengarkan...' : 'Mulai dengar',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _retryListening,
                      child: const Text('Coba rekam lagi'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextButton(
                      onPressed: _isBusy ? null : _openManualForm,
                      child: const Text('Input manual'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _statusText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
          ),
          if (_canOpenSettings) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: widget.speechService.openPermissionSettings,
              child: const Text('Buka pengaturan'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _prepareScreen() async {
    final SpeechPreparationResult result = await widget.speechService.prepare(
      requestPermission: false,
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isPreparing = false;
      _serviceState = result.state;
      _statusText = result.message;
      _canOpenSettings = result.shouldOpenSettings;
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _isBusy = true;
      _transcript = '';
      _soundLevel = 0;
    });

    final bool started = await widget.speechService.startListening(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
      onSoundLevelChange: (double level) {
        if (!mounted) {
          return;
        }
        setState(() {
          _soundLevel = level.clamp(0, 16);
        });
      },
      onResult: (SpeechRecognitionUpdate update) {
        if (!mounted) {
          return;
        }
        setState(() {
          _transcript = update.transcript;
          _serviceState = update.isFinal
              ? SpeechServiceState.completed
              : SpeechServiceState.listening;
          _statusText = update.isFinal
              ? 'Hasil rekaman siap diperiksa.'
              : 'Sedang mendengarkan...';
        });
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
      _serviceState = widget.speechService.status.state;
      _statusText = widget.speechService.status.message;
      _canOpenSettings = widget.speechService.status.shouldOpenSettings;
    });

    if (!started) {
      return;
    }
  }

  Future<void> _stopAndProcess() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
      _serviceState = SpeechServiceState.processing;
      _statusText = 'Memproses hasil suara...';
    });

    await widget.speechService.stopListening();
    final String transcript = _transcript.trim();
    if (transcript.isEmpty) {
      widget.speechService.markError(
        SpeechServiceFailure.noMatch,
        'Belum ada suara yang berhasil ditangkap. Silakan coba lagi atau gunakan input manual.',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _serviceState = widget.speechService.status.state;
        _statusText = widget.speechService.status.message;
      });
      return;
    }

    final List<Category> categories = await widget.categoryRepository
        .getAllActiveCategories();
    final VoiceTransactionParseResult parseResult = widget.parserService.parse(
      rawText: transcript,
      categories: categories,
    );
    final transcriptRecord = await widget.voiceTranscriptRepository
        .createTranscript(
          rawText: parseResult.originalTranscript,
          parsedType: parseResult.transactionType,
          parsedAmount: parseResult.amount,
          parsedCategoryUuid: parseResult.categoryUuid,
          confidenceScore: parseResult.confidenceScore.toDouble(),
        );

    widget.speechService.markCompleted();

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
      _serviceState = SpeechServiceState.completed;
      _statusText = 'Hasil rekaman siap diperiksa.';
    });

    final bool? transactionSaved = await context.push<bool>(
      RouteConstants.konfirmasiSuara,
      extra: VoiceConfirmationArguments(
        transcriptUuid: transcriptRecord.uuid,
        parseResult: parseResult,
      ),
    );

    if (!mounted || transactionSaved != true) {
      return;
    }

    // The confirmation screen only reports whether the transaction was saved.
    // After a successful voice transaction, reset the finance branch to its
    // root so the user returns to the main Keuangan screen.
    context.go(RouteConstants.keuangan);
  }

  Future<void> _retryListening() async {
    if (widget.speechService.isListening) {
      await widget.speechService.cancelListening(
        message: 'Perekaman sebelumnya dibatalkan. Silakan mulai lagi.',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _transcript = '';
      _soundLevel = 0;
      _serviceState = SpeechServiceState.idle;
      _statusText = 'Tekan tombol mulai untuk merekam transaksi suara.';
      _canOpenSettings = false;
    });
  }

  Future<void> _openManualForm() async {
    final bool? transactionSaved = await context.push<bool>(
      RouteConstants.transaksiBaru,
      extra: AddEditTransactionArguments(
        source: 'voice',
        initialNote: _transcript.isEmpty ? null : _transcript,
        originalTranscript: _transcript.isEmpty ? null : _transcript,
      ),
    );

    if (!mounted || transactionSaved != true) {
      return;
    }

    // Keep the direct manual fallback from the voice screen consistent with
    // the normal voice-confirmation flow.
    context.go(RouteConstants.keuangan);
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) {
      return;
    }
    if (status == SpeechToText.doneStatus && _transcript.trim().isNotEmpty) {
      _stopAndProcess();
      return;
    }

    setState(() {
      switch (status) {
        case SpeechToText.listeningStatus:
          _serviceState = SpeechServiceState.listening;
          _statusText = 'Sedang mendengarkan...';
          break;
        case SpeechToText.notListeningStatus:
          if (_transcript.trim().isNotEmpty) {
            _serviceState = SpeechServiceState.completed;
            _statusText = 'Hasil rekaman siap diperiksa.';
          } else {
            _serviceState = SpeechServiceState.idle;
            _statusText = 'Perekaman selesai. Tekan mulai untuk mencoba lagi.';
          }
          break;
        case SpeechToText.doneStatus:
          _serviceState = SpeechServiceState.completed;
          _statusText = _transcript.trim().isEmpty
              ? 'Tidak ada ucapan yang berhasil dikenali.'
              : 'Hasil rekaman siap diperiksa.';
          break;
      }
    });
  }

  void _handleSpeechError(SpeechServiceFailure failure, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _serviceState = SpeechServiceState.error;
      _statusText = message;
      _canOpenSettings =
          failure == SpeechServiceFailure.microphonePermanentlyDenied;
    });
  }

  String _stateLabel() {
    switch (_serviceState) {
      case SpeechServiceState.unavailable:
        return 'Status: Tidak tersedia';
      case SpeechServiceState.idle:
        return 'Status: Siap';
      case SpeechServiceState.listening:
        return 'Status: Mendengarkan';
      case SpeechServiceState.processing:
        return 'Status: Memproses';
      case SpeechServiceState.completed:
        return 'Status: Selesai';
      case SpeechServiceState.error:
        return 'Status: Perlu perhatian';
    }
  }

  Color _statusBorderColor() {
    switch (_serviceState) {
      case SpeechServiceState.error:
      case SpeechServiceState.unavailable:
        return AppColors.warning;
      case SpeechServiceState.listening:
        return AppColors.primary;
      default:
        return AppColors.border;
    }
  }
}
