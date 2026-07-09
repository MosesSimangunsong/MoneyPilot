import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  bool _isInitializing = true;
  bool _isSupported = false;
  String _transcript = '';
  String _statusText = 'Siap mendengar transaksi suara.';
  bool _isBusy = false;
  bool _hasProcessedCurrentTranscript = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    widget.speechService.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Ucapkan transaksi harianmu dalam Bahasa Indonesia, lalu periksa hasilnya sebelum disimpan.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    widget.speechService.isListening
                        ? Icons.graphic_eq
                        : LucideIcons.mic,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                          ? 'Contoh: Saya beli kopi lima belas ribu'
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
            const SizedBox(height: AppSpacing.xl),
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (!_isSupported)
              _buildUnsupportedState(context)
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy || !widget.speechService.isListening
                          ? null
                          : _stopAndProcess,
                      icon: const Icon(LucideIcons.square),
                      label: const Text('Berhenti'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy
                          ? null
                          : widget.speechService.isListening
                          ? null
                          : _startListening,
                      icon: const Icon(LucideIcons.mic),
                      label: Text(
                        widget.speechService.isListening
                            ? 'Mendengar...'
                            : 'Mulai dengar',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Izin mikrofon atau layanan speech-to-text belum tersedia di perangkat ini. Kamu tetap bisa lanjut ke form manual dengan catatan suara kosong.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () {
            context.push(
              '/keuangan/transaksi-baru',
              extra: AddEditTransactionArguments(
                source: 'voice',
                initialNote: _transcript,
              ),
            );
          },
          child: const Text('Buka form manual'),
        ),
      ],
    );
  }

  Future<void> _initializeSpeech() async {
    final bool initialized = await widget.speechService.initialize(
      onStatus: (String status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' && _transcript.trim().isNotEmpty) {
          _stopAndProcess();
        }
      },
      onError: (String error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Voice input gagal: $error')));
        setState(() {
          _statusText = 'Coba rekam lagi setelah izin mikrofon siap.';
          _isBusy = false;
        });
      },
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
      _isSupported = initialized;
      _statusText = initialized
          ? 'Tekan tombol mulai lalu ucapkan transaksi.'
          : 'Speech-to-text belum siap di perangkat ini.';
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _transcript = '';
      _statusText = 'Sedang mendengar...';
      _hasProcessedCurrentTranscript = false;
    });

    await widget.speechService.startListening(
      onResult: (String text, bool isFinal) {
        if (!mounted) {
          return;
        }
        setState(() {
          _transcript = text.trim();
          _statusText = isFinal
              ? 'Hasil rekaman siap diperiksa.'
              : 'Mendengar ucapanmu...';
        });
      },
    );
  }

  Future<void> _stopAndProcess() async {
    if (_isBusy || _hasProcessedCurrentTranscript) {
      return;
    }
    _hasProcessedCurrentTranscript = true;

    await widget.speechService.stopListening();
    final String transcript = _transcript.trim();
    if (transcript.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada suara yang berhasil ditangkap.'),
        ),
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _statusText = 'Memproses hasil suara...';
    });

    final List<Category> categories = await widget.categoryRepository
        .getAllActiveCategories();
    final ParsedVoiceTransaction draft = widget.parserService.parse(
      rawText: transcript,
      categories: categories,
    );
    final transcriptRecord = await widget.voiceTranscriptRepository
        .createTranscript(
          rawText: draft.rawText,
          parsedType: draft.type,
          parsedAmount: draft.amount,
          parsedCategoryUuid: draft.categoryUuid,
          confidenceScore: draft.confidenceScore,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
    });

    if (draft.shouldOpenManualForm) {
      await context.push(
        '/keuangan/transaksi-baru',
        extra: AddEditTransactionArguments(
          source: 'voice',
          transcriptUuid: transcriptRecord.uuid,
          initialTitle: draft.title,
          initialType: draft.type,
          initialCategoryUuid: draft.categoryUuid,
          initialNote: draft.rawText,
        ),
      );
      return;
    }

    await context.push(
      '/keuangan/suara/konfirmasi',
      extra: VoiceConfirmationArguments(
        transcriptUuid: transcriptRecord.uuid,
        draft: draft,
      ),
    );
  }
}
